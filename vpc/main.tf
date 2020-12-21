provider "aws" {
  region = var.region
}

locals {
  az1 = "${var.region}a"
  az2 = "${var.region}b"

  # cidrsubnet() function creates a Cidr address in the VpcCidr https://www.terraform.io/docs/configuration/functions/cidrsubnet.html.
  public_cidr_block1 = cidrsubnet(var.vpc_cidr, 8, 0)
  public_cidr_block2 = cidrsubnet(var.vpc_cidr, 8, 1)

  private_cidr_block1 = cidrsubnet(var.vpc_cidr, 8, 10)
  private_cidr_block2 = cidrsubnet(var.vpc_cidr, 8, 11)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"
  name    = "ops-${var.environment}-vpc"
  cidr    = var.vpc_cidr

  azs             = [local.az1, local.az2]
  public_subnets  = [local.public_cidr_block1, local.public_cidr_block2]
  private_subnets = [local.private_cidr_block1, local.private_cidr_block2]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    terraform   = "true"
    environment = var.environment
  }
}