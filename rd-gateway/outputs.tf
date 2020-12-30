output "rdgw_eip" {
  description = "The public IP associated with the RD Gateway instance"
  value       = aws_eip.main.public_ip
}

output "rdgw_sg" {
  description = "The ID of the security group associated with the RD Gateway"
  value       = aws_security_group.main.id
}