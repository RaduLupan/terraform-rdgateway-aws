#----------------------------------------------------------------------------
# REQUIRED PARAMETERS: You must provide a value for each of these parameters.
#----------------------------------------------------------------------------

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "route53_public_zone" {
  description = "The name of the public Route 53 zone (aka domain name) that Letsencrypt certificates are issued for"
  type        = string
  default     = null
}

variable "certbot_zip" {
  description = "The name of the certbot zip artifact to use i.e. certbot-0.27.1.zip"
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

variable "s3_prefix" {
  description = "Prefix to use for the S3 bucket name"
  type        = string
  default     = "letsencrypt-certbot-lambda"
}

variable "subdomain_name" {
  description = "The name of the subdomain if applicable i.e. ops"
  type        = string
  default     = null
}

variable "email" {
  description = "The email address that Letsencrypt sends notifications to"
  type        = string
  default     = null
}

