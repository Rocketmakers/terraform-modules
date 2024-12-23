output "network_name" {
  description = "The name for the CI network"
  value       = google_compute_network.ci_network.name
}

output "network_self_link" {
  description = "The self link for the CI network"
  value       = google_compute_network.ci_network.self_link
}

output "subnetwork_ip_cidr" {
  description = "The IP CIDR for the subnetwork. The default supports 14 addresses"
  value       = var.subnetwork_ip_cidr
}