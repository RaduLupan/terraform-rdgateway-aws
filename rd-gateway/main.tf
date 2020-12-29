provider "aws" {
  region = var.region
}

# Calculated local values.
locals {
  vpc_id = data.aws_subnet.selected.vpc_id

  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]

  rdp_port = 3389

  ports_source_map = {
    "443"  = "0.0.0.0/0"
    "3389" = local.rdgw_allowed_cidr
  }

  rdgw_allowed_cidr = var.rdgw_allowed_cidr == null ? "0.0.0.0/0" : var.rdgw_allowed_cidr

  common_tags = {
    terraform   = true
    environment = var.environment
  }
}

# Use this data source to retrieve details about a specific VPC subnet.
data "aws_subnet" "selected" {
  id = var.public_subnet_id
}

# Use this data source to get the ID of a registered AMI for use in other resources.
data "aws_ami" "windows2019" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# Security group.
resource "aws_security_group" "main" {
  name   = "${var.rdgw_name}-sg"
  vpc_id = local.vpc_id

  tags = {
    Name        = "${var.rdgw_name}-sg"
    terraform   = true
    environment = var.environment
  }
}

# Ingress rules.
resource "aws_security_group_rule" "ingress" {
  for_each = local.ports_source_map

  type              = "ingress"
  description       = "Inbound TCP ${each.key}"
  security_group_id = aws_security_group.main.id

  from_port   = each.key
  to_port     = each.key
  protocol    = local.tcp_protocol
  cidr_blocks = [each.value]
}

# Egress rule: allow all outbound traffic.
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.main.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

# Use this data set to replace embedded bash scripts such as user_data with scripts that sit on different source.
data "template_file" "user_data" {
  template = file("${path.module}/user-data.ps1")

  vars = {
    region        = var.region
    computer_name = var.rdgw_name
    
    s3_bucket     = var.s3_bucket
    s3_bucket_tls = var.s3_bucket_tls
    s3_folder_tls = var.s3_folder_tls

    sqs_url       = var.sqs_url
    script1       = var.scripts["1_of_3"]
    script2       = var.scripts["2_of_3"]
    script3       = var.scripts["3_of_3"]
  }
}

# IAM instance profile.
resource "aws_iam_instance_profile" "main" {
  name = "${var.rdgw_name}-profile"
  role = aws_iam_role.main.name
}

# IAM instance role
resource "aws_iam_role" "main" {
  name = "${var.rdgw_name}-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = local.common_tags
}

# IAM instance policy
resource "aws_iam_role_policy" "main" {
  name = "${var.rdgw_name}-policy"
  role = aws_iam_role.main.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "SSMAccess",
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Sid": "S3Access",
        "Action": [
          "s3:GetObject"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Sid": "SQSAccess",
        "Action": [
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

# RD Gateway EC2 instance.
resource "aws_instance" "rdgw" {
  ami           = data.aws_ami.windows2019.id
  instance_type = var.rdgw_instance_type

  key_name               = var.key_name
  monitoring             = true
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.main.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = "150"
    encrypted   = "true"
  }

  user_data = data.template_file.user_data.rendered

  iam_instance_profile = aws_iam_instance_profile.main.name

  tags = {
    Name        = var.rdgw_name
    terraform   = true
    environment = var.environment
  }
}

# Elastic IP.
resource "aws_eip" "main" {
  vpc = true
}

# Elastic IP association.
resource "aws_eip_association" "main" {
  instance_id   = aws_instance.rdgw.id
  allocation_id = aws_eip.main.id
}

# This data source allows to find a Hosted Zone ID given Hosted Zone name and certain search criteria.
data "aws_route53_zone" "selected" {
  count = var.route53_public_zone == null ? 0 : 1

  name         = var.route53_public_zone
  private_zone = false
}

# Create A record in Route 53 zone.
resource "aws_route53_record" "rdgw" {
  count = var.route53_public_zone == null ? 0 : 1

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "${var.rdgw_name}.ops.${data.aws_route53_zone.selected[0].name}"
  type    = "A"
  ttl     = "60"
  records = [aws_eip.main.public_ip]
}