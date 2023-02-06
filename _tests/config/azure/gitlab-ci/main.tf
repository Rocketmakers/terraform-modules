locals {
  project_name = "terratest"
  location     = "West Europe"
}

module "gitlab_ci" {
  source = "../../../../azure/gitlab-ci"

  primary_location          = local.location
  project_prefix            = local.project_name
  container_registry_name   = azurerm_container_registry.acr.name
  key_vault_name            = "terratest"
  runner_registration_token = data.gitlab_project.runner_token.runners_token
  ssh_cidr_ranges           = [var.cidr_range]

  # The following are provided via test code
  resource_group_name = var.resource_group_name
  runner_tags         = [var.runner_tag]
  instance_count      = var.instance_count

  depends_on = [
    azurerm_container_registry.acr
  ]
}

resource "azurerm_container_registry" "acr" {
  name                = "rocketmakers${local.project_name}"
  resource_group_name = var.resource_group_name
  location            = local.location
  sku                 = "Basic"
}

data "gitlab_project" "runner_token" {
  id = "33153506"
}
