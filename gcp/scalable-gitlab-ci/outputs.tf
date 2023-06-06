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
  value       = google_compute_address.orchestrator_static_ip.address
}

output "orchestrator_internal_ip_address" {
  description = "Internal network IP address of the orchestrator instance"
  value       = google_compute_instance.orchestrator.network_interface[0].network_ip
}

output "orchestrator_service_account_key" {
  description = "Google service account key for the orchestrator"
  value       = module.orchestrator_account.key
  sensitive   = true
}

output "orchestrator_service_account_email" {
  description = "Google service account email for the orchestrator"
  value       = module.orchestrator_account.email
}

output "runner_service_account_key" {
  description = "Google service account key for the runner(s)"
  value       = module.runner_account.key
  sensitive   = true
}

output "runner_service_account_email" {
  description = "Google service account email for the runner(s)"
  value       = module.runner_account.email
}

## Deprecated

output "service_account_key" {
  description = "[Deprecated] Google service account key. Use orchestrator_service_account_key instead"
  value       = module.orchestrator_account.key
  sensitive   = true
}

output "service_account_email" {
  description = "[Deprecated] Google service account email. Use orchestrator_service_account_email instead"
  value       = module.orchestrator_account.email
}

output "username" {
  description = "[Deprecated] Username for CI box. Use orchestrator_username instead"
  value       = var.username
}

output "private_key" {
  description = "[Deprecated] Private SSH key. Use orchestrator_private_key instead"
  value       = tls_private_key.orchestrator_ssh.private_key_pem
  sensitive   = true
}

output "public_key" {
  description = "[Deprecated] Public SSH key. Use orchestrator_public_key instead"
  value       = tls_private_key.orchestrator_ssh.public_key_openssh
}
