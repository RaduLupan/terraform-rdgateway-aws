output "ad_directory_id" {
  description = "The ID of the AD directory"
  value       = local.directory_id
}

output "ad_dns_ips" {
  description = "The IPs of the DNS servers for the AD domain"
  value       = local.dns_ip_addresses
}

output "ad_domain_fqdn" {
  description = "The  fully qualified domain name of the AD domain, i.e. example.com"
  value       = var.ad_domain_fqdn
}