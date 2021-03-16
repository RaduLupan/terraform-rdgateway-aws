#----------------------------------------------------------------------------
# REQUIRED PARAMETERS: You must provide a value for each of these parameters.
#----------------------------------------------------------------------------

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "key_name" {
  description = "The name of the key pair that allows to securely connect to the instance after launch"
  type        = string
}

variable "private_subnet_id" {
  description = "The  ID of a private subnet in the VPC where the RD Session Host will be deployed"
  type        = string
}

variable "rdgw_sg" {
  description = "The ID of the security group attached to the RD Gateway"
  type        = string
}

variable "ad_directory_id" {
  description = "The ID of the AD domain (if null the RD Gateway will NOT be joined to domain)"
  type        = string
}

variable "ad_dns_ips" {
  description = "The IPs of the DNS servers for the AD domain"
  type        = list(string)
}

variable "ad_domain_fqdn" {
  description = "The  fully qualified domain name of the AD domain, i.e. example.com"
  type        = string
}

#---------------------------------------------------------------
# OPTIONAL PARAMETERS: These parameters have resonable defaults.
#---------------------------------------------------------------

variable "environment" {
  description = "Environment i.e. dev, test, stage, prod"
  type        = string
  default     = "dev"
}

variable "rdsh_instance_type" {
  description = "The EC2 instance type for the RD Session Host server"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "The ID of the AWS EC2 AMI to use (if null the latest Windows Server 2019 is selected)"
  type        = string
  default     = null
}

variable "download_url" {
  description = "The URL for the Office Deployment Tool Click-to-Run installer"
  type        = string
  default     = null
}