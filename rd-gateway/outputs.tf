output "rdgw_eip" {
  description = "The public IP associated with the RD Gateway instance"
  value       = aws_eip.main.public_ip
}