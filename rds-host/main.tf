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
  name   = "rds-host-sg"
  vpc_id = local.vpc_id

  tags = {
    Name        = "rds-host-sg"
    terraform   = true
    environment = var.environment
  }
}

/*
# Ingress rules.
resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  description       = "Inbound TCP ${local.rdp_port}"
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

    sqs_url         = var.sqs_url
    create_task_ps1 = var.scripts["create_task"]
    renew_tls_ps1   = var.scripts["renew_tls"]
    get_tls_ps1     = var.scripts["get_tls"]

    sns_arn   = local.sns_arn
    host_name = local.host_name
  }
}

# IAM instance profile.
resource "aws_iam_instance_profile" "main" {
  name = "${var.rdgw_name}-profile"
  role = aws_iam_role.main.name
}

# Template file for the EC2 instance role trust policy.
data "template_file" "ec2_role_trust" {
  template = file("${path.module}/ec2-role-trust.json.tpl")
}

# IAM instance role
resource "aws_iam_role" "main" {
  name = "${var.rdgw_name}-role"
  path = "/"

  assume_role_policy = data.template_file.ec2_role_trust.rendered
  tags               = local.common_tags
}

# Template file for the EC2 instance role IAM policy.
data "template_file" "ec2_role_policy" {
  template = file("${path.module}/ec2-role-policy.json.tpl")
}

# IAM instance policy
resource "aws_iam_role_policy" "main" {
  name = "${var.rdgw_name}-policy"
  role = aws_iam_role.main.id

  policy = data.template_file.ec2_role_policy.rendered
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

# Create template file for the SSM document if var.ad_directory_id is not null.
data "template_file" "ssm_document" {
  count = var.ad_directory_id == null ? 0 : 1

  template = file("${path.module}/ssm-document.json.tpl")

  vars = {
    ad_directory_id = var.ad_directory_id
    ad_domain_fqdn  = var.ad_domain_fqdn
    ad_dns_ip1      = var.ad_dns_ips[0]
    ad_dns_ip2      = var.ad_dns_ips[1]
  }
}

# Create the SSM document if var.ad_directory_id is not null.
resource "aws_ssm_document" "main" {
  count = var.ad_directory_id == null ? 0 : 1

  name          = "${var.ad_domain_fqdn}-domain-join"
  document_type = "Command"

  content = data.template_file.ssm_document[0].rendered
}

# Create the SSM association if var.ad_directory_id is not null.
resource "aws_ssm_association" "main" {
  count = var.ad_directory_id == null ? 0 : 1

  name = aws_ssm_document.main[0].name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.rdgw.id]
  }
}

*/