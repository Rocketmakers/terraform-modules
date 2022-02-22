output "username" {
  description = "Username for CI box"
  value       = var.username
}

output "private_key" {
  description = "Private SSH key"
  value       = tls_private_key.ci_ssh.private_key_pem
}

output "public_key" {
  description = "Public SSH key"
  value       = tls_private_key.ci_ssh.public_key_openssh
}

output "ip_addresses" {
  description = "Static IP address of each instance"
  value       = google_compute_address.ci_static_ip.*.address
}

output "internal_ip_addresses" {
  description = "Internal network IP address of each instance"
  value = [
    for instance in google_compute_instance.ci_box :
    length(instance.network_interface) > 0 ? instance.network_interface[0].network_ip : "NOT SET"
  ]
}

