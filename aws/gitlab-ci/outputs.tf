output "username" {
  description = "Username for CI box"
  value       = var.username
}

output "private_key" {
  description = "Private SSH key"
  value       = tls_private_key.ci_ssh.private_key_pem
}

output "public_key" {
  description = "Public SSH key"
  value       = tls_private_key.ci_ssh.public_key_openssh
}

output "addresses" {
  description = "CI static IP addresses"
  value       = aws_eip.ci[*].public_ip
}

output "internal_addresses" {
  description = "CI box network IP addresses"
  value       = aws_eip.ci[*].private_ip
}
