data "azurerm_subscription" "sub" {}

# Service principals are Applications within Azure. They define the permission set for the service principal.

resource "azuread_application" "app" {
  display_name = "terraform-modules-terratest-ci"
}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.app.application_id
}

resource "azuread_service_principal_password" "pw" {
  service_principal_id = azuread_service_principal.sp.object_id
}

resource "azurerm_role_assignment" "owner" {
  scope                = data.azurerm_subscription.sub.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.sp.object_id
}

data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_app_role_assignment" "app_rw" {
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
  principal_object_id = azuread_service_principal.sp.object_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}
