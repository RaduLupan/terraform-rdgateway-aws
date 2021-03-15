provider "aws" {
  region = var.region
}

# Calculated local values.
locals {
  vpc_id = data.aws_subnet.selected.vpc_id

  ami_id            = var.ami_id == null ? data.aws_ami.windows2019[0].id : var.ami_id
  count_ami_win2019 = var.ami_id == null ? 1 : 0

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
  id = var.private_subnet_id
}

# Use this data source to get the ID of a registered AMI for use in other resources.
data "aws_ami" "windows2019" {
  count = local.count_ami_win2019

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


# Ingress rules: RDP allowed from the RD Gateway security group only!
resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  description       = "Inbound TCP ${local.rdp_port}"
  security_group_id = aws_security_group.main.id

  from_port                = local.rdp_port
  to_port                  = local.rdp_port
  protocol                 = local.tcp_protocol
  source_security_group_id = var.rdgw_sg
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

# RD Session Host EC2 instance.
resource "aws_instance" "rdsh" {
  ami           = local.ami_id
  instance_type = var.rdsh_instance_type

  key_name               = var.key_name
  monitoring             = true
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.main.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = "150"
    encrypted   = "true"
  }

  user_data = data.template_file.user_data.rendered

  iam_instance_profile = "rdgateway-profile"

  tags = {
    Name        = "rd-session-host"
    terraform   = true
    environment = var.environment
  }
}

# Create the SSM association.
resource "aws_ssm_association" "main" {
  name = "derasys.ad-domain-join"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.rdsh.id]
  }
}

# Use this data set to replace embedded bash scripts such as user_data with scripts that sit on different source.
data "template_file" "user_data" {
  template = file("${path.module}/user-data.ps1")

  vars = {
    computer_name = "rdsh01"
    download_url  = var.download_url
  }
}
