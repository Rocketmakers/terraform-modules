output "service_account_email" {
  description = "The email of the service account associated with the runners"
  value       = module.ci.service_account_email
}

output "service_account_key" {
  description = "The email address of the service account associated with the runners"
  value       = module.ci.service_account_key
  sensitive   = true
}

output "runner_service_account_key" {
  description = "Google service account key for the runner"
  value       = module.ci.runner_service_account_key
  sensitive   = true
}

output "runner_service_account_email" {
  description = "Google service account email for the runner"
  value       = module.ci.runner_service_account_email
}
