locals {
  project_name = "terratest"
  location     = "West Europe"
}

module gitlab_ci {
  source = "../../../../azure/gitlab-ci"

  resource_group                = var.resource_group_name
  primary_location              = local.location
  project_name                  = local.project_name
  container_registry_name       = azurerm_container_registry.acr.name
  key_vault_name                = "terratest"
  registration_token_project_id = "33153506"
  whitelist = [
    # Rocketmakers office
    "212.139.176.173",
  ]

  # The following are provided via test code
  runner_tags    = [var.runner_tag]
  instance_count = var.instance_count

  depends_on = [
    azurerm_container_registry.acr
  ]
}

resource azurerm_container_registry acr {
  name                = "rocketmakers${local.project_name}"
  resource_group_name = var.resource_group_name
  location            = local.location
  sku                 = "Basic"
}
