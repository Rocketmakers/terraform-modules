output "runner_client_id" {
  description = "The client id for the runner"
  value       = module.scalable_gitlab_ci.runner_client_id
}

output "runner_client_secret" {
  description = "The client secret for the runner"
  value       = module.scalable_gitlab_ci.runner_client_secret
  sensitive   = true
}

output "runner_principal_id" {
  description = "The principal id for the runner"
  value       = module.scalable_gitlab_ci.runner_principal_id
}

output "orchestrator_private_key" {
  description = "Private SSH key for the orchestrator instance"
  value       = module.scalable_gitlab_ci.orchestrator_private_key
  sensitive   = true
}

output "orchestrator_public_ip_address" {
  description = "Static IP address of the orchestrator instance"
  value       = module.scalable_gitlab_ci.orchestrator_public_ip_address
}
