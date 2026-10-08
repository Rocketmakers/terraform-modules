# scalable-azure-github-ci

This module creates a VM scale set of GitHub runners which scale up and down when jobs are being processed by the primary runner.

{{{ this.coreContent }}}

## Known Issues

### `terraform destroy` fails to delete the container app environment

With azurerm 5.x, `terraform destroy` can fail to delete the container app environment (`<name>-ci`). The provider returns an error and keeps the resource in state even though Azure has deleted it (or is deleting it). See [hashicorp/terraform-provider-azurerm#33433](https://github.com/hashicorp/terraform-provider-azurerm/issues/33433).

If this happens:

1. Delete the container app environment manually, if it still exists, from the Azure portal or with the Azure CLI:

   ```
   az containerapp env delete --name <name>-ci --resource-group <resource_group_name> --yes
   ```

2. Remove the container app environment from Terraform state, if it is still there:

   ```
   terraform state rm 'module.<module_name>.azurerm_container_app_environment.ci'
   ```

3. Run `terraform destroy` again.

## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/scalable-github-ci?ref=v{{{ this.version }}}"

  resource_group_name = var.resource_group_name
  primary_location    = var.primary_location

  name = var.name

  ssh_cidr_ranges = var.ssh_cidr_range
  vm_sizes        = ["Standard_B2s"]

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
