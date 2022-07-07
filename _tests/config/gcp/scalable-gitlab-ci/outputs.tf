output "service_account_key" {
  description = "Google service account key"
  value       = module.ci.service_account_key
  sensitive   = true
}

output "service_account_email" {
  description = "Google service account email"
  value       = module.ci.service_account_email
}

output "orchestrator_private_key" {
  description = "Google service account email"
  value       = module.ci.private_key
  sensitive   = true
}

