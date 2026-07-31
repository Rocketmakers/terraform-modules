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
    azurerm_user_assigned_identity.ci_box.principal_id
  ]
}

output "virtual_network_id" {
  description = "The id of the virtual network associated with the CI runner"
  value       = azurerm_virtual_network.ci.id
}

output "virtual_network_name" {
  description = "The name of the virtual network associated with the CI runner"
  value       = azurerm_virtual_network.ci.name
}

output "subnet_id" {
  description = "The id of the subnet the CI runner is assigned to"
  value       = azurerm_subnet.ci.id
}

output "virtual_machine_scale_set_id" {
  description = "The id of the virtual machine scale set for the CI runner"
  value       = azurerm_orchestrated_virtual_machine_scale_set.ci_box.id
}

output "github_webhook_secret" {
  description = "The secret supplied in all GitHub webhook requests"
  value       = random_string.github_secret.result
}

output "autoscaler_public_url" {
  description = "The public URL of the autoscaler"
  value       = azurerm_container_app.autoscaler.ingress[0].fqdn

}