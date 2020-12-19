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
/*data "template_file" "user_data" {
  template = file("${path.module}/user-data.ps1")
}*/

resource "aws_instance" "rdgw" {
  ami           = data.aws_ami.windows2019.id
  instance_type = var.rdgw_instance_type

  key_name        = var.key_name
  monitoring      = true
  subnet_id       = var.public_subnet_id
  security_groups = [aws_security_group.main.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = "150"
    encrypted   = "true"
  }

  #user_data = data.template_file.user_data.rendered

  #iam_instance_profile = local.iam_instance_profile

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