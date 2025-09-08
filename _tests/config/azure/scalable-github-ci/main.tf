locals {
  name = "ghubscalableci"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.primary_location
}

resource "azurerm_container_registry" "acr" {
  name                = "rocketmakers${local.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.primary_location
  sku                 = "Basic"
}

module "scalable_gitlab_ci" {
  source = "../../../../azure/scalable-github-ci"

  container_registry_name                = azurerm_container_registry.acr.name
  container_registry_resource_group_name = azurerm_resource_group.rg.name
  github_organisation                    = "rocketmakers"
  autoscaler_webhook_repo_name           = "terraform-modules"
  subnet_service_endpoints               = ["Microsoft.KeyVault"]
  resource_group_name                    = azurerm_resource_group.rg.name
  vm_size                                = "Standard_B2ms"
  name                                   = local.name

  # The following are provided via test code
  github_api_token = var.github_api_token
  primary_location = var.primary_location
  runner_labels    = [var.runner_label]
  ssh_cidr_ranges  = [var.cidr_range]

  depends_on = [
    azurerm_container_registry.acr
  ]
}
