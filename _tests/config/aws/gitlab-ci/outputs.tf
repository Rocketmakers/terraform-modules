output "username" {
  description = "Username for CI box"
  value       = module.gitlab_ci.username
}

output "private_key" {
  description = "Private SSH key"
  value       = module.gitlab_ci.private_key
  sensitive   = true
}

output "public_key" {
  description = "Public SSH key"
  value       = module.gitlab_ci.public_key
}

output "ip_addresses" {
  description = "CI static IP addresses"
  value       = module.gitlab_ci.ip_addresses
}

output "internal_ip_addresses" {
  description = "CI box network IP addresses"
  value       = module.gitlab_ci.internal_ip_addresses
}
