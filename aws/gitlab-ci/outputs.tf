output "username" {
  description = "Username for CI box"
  value       = var.image_config.default_username
}

output "private_key" {
  description = "Private SSH key"
  value       = tls_private_key.ci_ssh.private_key_pem
  sensitive   = true
}

output "public_key" {
  description = "Public SSH key"
  value       = tls_private_key.ci_ssh.public_key_openssh
}

output "ip_addresses" {
  description = "CI static IP addresses"
  value       = aws_eip.ci[*].public_ip
}

output "internal_ip_addresses" {
  description = "CI box network IP addresses"
  value       = aws_eip.ci[*].private_ip
}
