output "username" {
  description = "Username for CI box"
  value       = var.username
}

output "private_key" {
  description = "Private SSH key"
  value       = tls_private_key.orchestrator_ssh.private_key_pem
  sensitive   = true
}

output "public_key" {
  description = "Public SSH key"
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

output "service_account_key" {
  description = "Google service account key"
  value       = module.orchestrator_account.key
  sensitive   = true
}

output "service_account_email" {
  description = "Google service account email"
  value       = module.orchestrator_account.email
}

