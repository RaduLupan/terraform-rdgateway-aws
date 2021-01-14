#----------------------------------------------------------------------------
# REQUIRED PARAMETERS: You must provide a value for each of these parameters.
#----------------------------------------------------------------------------

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "ad_directory_type" {
  description = "What type of directory: SimpleAD or MicrosoftAD?"
  type        = string

  validation {
    condition     = var.ad_directory_type == "SimpleAD" || var.ad_directory_type == "MicrosoftAD"
    error_message = "The directory type must be either SimpleAD or MicrosoftAD."
  }
}

variable "ad_domain_fqdn" {
  description = "The  fully qualified domain name of the AD domain, i.e. example.com"
  type        = string
}

variable "ad_admin_password" {
  description = "The  password for the admin/administrator account"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC the AD directory will be deployed in"
  type        = string
}

variable "subnet_ids" {
  description = "The list of private subnet IDs that the domain controllers will be deployed in"
  type        = list(string)
}