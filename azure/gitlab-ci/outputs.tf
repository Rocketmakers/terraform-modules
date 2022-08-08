output "username" {
  description = "Username for CI box"
  value       = var.username
}

output "private_key" {
  description = "CI Box private key - used for SSH"
  value       = tls_private_key.ci_ssh.private_key_pem
  sensitive   = true
}

output "public_key" {
  description = "Public SSH key"
  value       = tls_private_key.ci_ssh.public_key_openssh
}

output "ip_addresses" {
  description = "CI Box public IP address"
  value       = azurerm_public_ip.ci[*].ip_address
}

output "internal_ip_addresses" {
  description = "Internal network IP address of each instance"
  value = [
    for instance in azurerm_network_interface.ci : instance.private_ip_address
  ]
}

output "service_principal_ids" {
  description = "The ids of the underlying service principal accounts"
  value = [
    for instance in azurerm_virtual_machine.ci_box: instance.identity[0].principal_id
  ]
}