module "scalable_gitlab_ci" {
  source = "../../../../azure/scalable-gitlab-ci"

  container_registry_name   = azurerm_container_registry.acr.name
  gitlab_token              = data.gitlab_project.runner_token.runners_token
  subnet_service_endpoints  = ["Microsoft.KeyVault"]
  idle_time_seconds         = 10
  orchestrator_storage_type = "Standard_LRS"
  runner_storage_type       = "Premium_LRS"
  resource_group_name       = azurerm_resource_group.rg.name
  core_resource_group_name  = azurerm_resource_group.rg.name

  # The following are provided via test code
  primary_location       = var.primary_location
  project_prefix         = var.project_prefix
  runner_tags            = [var.runner_tag]
  gitlab_max_runners     = var.gitlab_max_runners
  max_builds_per_machine = var.max_builds_per_machine
  trusted_cidr_ranges    = [var.cidr_range]
  runner_machine_name    = var.runner_machine_name

  depends_on = [
    azurerm_container_registry.acr
  ]
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.primary_location
}

resource "azurerm_container_registry" "acr" {
  name                = "rocketmakers${var.project_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.primary_location
  sku                 = "Basic"
}

data "gitlab_project" "runner_token" {
  id = "33153506"
}
