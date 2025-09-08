# scalable-azure-github-ci

This module creates a VM scale set of GitHub runners which scale up and down when jobs are being processed by the primary runner.

{{{ this.coreContent }}}

## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/scalable-github-ci?ref=v{{{ this.version }}}"

  resource_group_name = var.resource_group_name
  primary_location    = var.primary_location

  name = var.name

  ssh_cidr_ranges = var.ssh_cidr_range
  vm_size         = "Standard_B2s"

  github_api_token = var.github_runner_token
  github_organisation = "Rocketmakers/terraform-modules" # We want to register just for our repository

  container_registry_name                = var.container_registry_name
  container_registry_resource_group_name = var.container_registry_resource_group_name

  min_instance_count = 1
  max_instance_count = 3

  subnet_service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ]
}
```
