output "orchestrator_service_account_email" {
  description = "The email of the service account associated with the orchestrator"
  value       = module.ci.service_account_email
}

output "orchestrator_service_account_key" {
  description = "The key of the service account associated with the orchestrator"
  value       = module.ci.service_account_key
  sensitive   = true
}

output "runner_service_account_email" {
  description = "The email of the service account associated with the runner(s)"
  value       = module.ci.runner_service_account_email
}

output "runner_service_account_key" {
  description = "The key of the service account associated with the runner(s)"
  value       = module.ci.runner_service_account_key
  sensitive   = true
}