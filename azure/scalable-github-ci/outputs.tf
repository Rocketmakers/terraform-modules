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

output "service_principal_ids" {
  description = "The ids of the underlying service principal accounts"
  value = [
    azurerm_linux_virtual_machine_scale_set.ci_box.identity[0].principal_id
  ]
}

output "subnet_id" {
  description = "The id of the subnet the CI runner is assigned to"
  value       = azurerm_subnet.ci.id
}