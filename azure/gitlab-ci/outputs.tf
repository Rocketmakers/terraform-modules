output "private_key" {
  description = "CI Box private key - used for SSH"
  value       = tls_private_key.ci_ssh.private_key_pem
}

output "ip_addresses" {
  description = "CI Box public IP address"
  value       = azurerm_public_ip.ci[*].ip_address
}
