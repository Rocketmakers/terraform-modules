data "azurerm_subscription" "this" {}

# Service principals are Applications within Azure. They define the permission set for the service principal.

resource "azuread_application" "ci_access_application" {
  display_name = "ci-access"
}

resource "azuread_service_principal" "ci_service_principle" {
  application_id = azuread_application.ci_access_application.application_id
}

resource "azuread_service_principal_password" "ci_service_principle_password" {
  service_principal_id = azuread_service_principal.ci_service_principle.object_id
}

resource "azurerm_role_assignment" "ci_service_principle_role" {
  scope              = data.azurerm_subscription.this.id
  role_definition_id = "Contributor"
  principal_id       = azuread_service_principal.ci_service_principle.id
}