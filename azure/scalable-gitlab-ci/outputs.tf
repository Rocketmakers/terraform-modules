output "orchestrator_username" {
  description = "Username for orchestrator vm"
  value       = var.username
}

output "orchestrator_private_key" {
  description = "Private SSH key for the orchestrator instance"
  value       = tls_private_key.orchestrator_ssh.private_key_pem
  sensitive   = true
}

output "orchestrator_public_key" {
  description = "Public SSH key for the orchestrator instance"
  value       = tls_private_key.orchestrator_ssh.public_key_openssh
}

output "orchestrator_public_ip_address" {
  description = "Static IP address of the orchestrator instance"
  value       = azurerm_public_ip.ci.ip_address
}

output "orchestrator_internal_ip_address" {
  description = "Internal network IP address of the orchestrator instance"
  value       = azurerm_network_interface.ci.private_ip_address
}

output "runner_client_id" {
  description = "The client id for the runner"
  value       = azuread_application.runner.client_id
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
