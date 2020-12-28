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

variable "ad_dns_ips" {
  description = "The IPs of the DNS servers for the AD domain"
  type        = list(string)
}

variable "ad_directory_id" {
  description = "The ID of the AD domain"
  type        = string
}

variable "ad_domain_fqdn" {
  description = "The  fully qualified domain name of the AD domain, i.e. example.com"
  type        = string
}

variable "public_subnet_id" {
  description = "The  ID of a public subnet in the VPC where the RD Gateway will be deployed"
  type        = string
}

variable "s3_bucket" {
  description = "The name of the S3 bucket that contains the scripts to be installed on the EC2 instance"
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

variable "rdgw_instance_type" {
  description = "The EC2 instance type for the RD Gateway"
  type        = string
  default     = "t3.small"
}

variable "rdgw_allowed_cidr" {
  description = "The allowed CIDR IP range for RDP access to the RD Gateway"
  type        = string
  default     = null
}

variable "rdgw_name" {
  description = "The name of the RD Gateway instance"
  type        = string
  default     = "rdgw01"
}

variable "route53_public_zone" {
  description = "The name of the public Route 53 zone (aka domain name) that will hold the A record for the RD Gateway instance"
  type        = string
  default     = null
}

variable "scripts" {
  description = "The scripts in the S3 bucket that need to be downloaded on to the EC2 instance"
  type        = map(string)
  default     = {
    "1_of_3" =  "/scripts/create-scheduled-task.ps1"
    "2_of_3" =  "/scripts/get-latest-letsencrypt-tls.ps1"
    "3_of_3" =  "/scripts/renew-letsencrypt-tls.ps1"
  }
}