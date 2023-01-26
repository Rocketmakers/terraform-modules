output "display_name" {
  value = azuread_service_principal.ci_service_principle.display_name
}

output "object_id" {
  value = azuread_service_principal.ci_service_principle.id
}

output "client_id" {
  value = azuread_application.ci_access_application.application_id
}

output "client_secret" {
  value     = azuread_service_principal_password.ci_service_principle_password.value
  sensitive = true
}