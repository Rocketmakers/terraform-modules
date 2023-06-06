output "display_name" {
  value = azuread_service_principal.sp.display_name
}

output "object_id" {
  value = azuread_service_principal.sp.id
}

output "client_id" {
  value = azuread_application.app.application_id
}

output "client_secret" {
  value     = azuread_service_principal_password.pw.value
  sensitive = true
}
