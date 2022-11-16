output "username" {
  description = "Username for CI box"
  value       = var.username
}

output "private_key" {
  description = "CI Box private key - used for SSH"
  value       = tls_private_key.orchestrator_ssh.private_key_pem
  sensitive   = true
}

output "public_key" {
  description = "Public SSH key"
  value       = tls_private_key.orchestrator_ssh.public_key_openssh
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

output "runner_client_id" {
  description = "The client id for the runner"
  value       = azuread_application.runner.application_id
}

output "runner_client_secret" {
  description = "The client secret for the runner"
  value       = azuread_service_principal_password.runner.value
  sensitive   = true
}

output "runner_principal_id" {
  description = "The principal id for the runner"
  value       = azuread_service_principal.runner.object_id
}

output "subnet_id" {
  description = "The id for the network subnet"
  value       = azurerm_subnet.ci.id
}
