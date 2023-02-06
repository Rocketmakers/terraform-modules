# scalable-azure-ci

This module creates an orchestrator VM inside Azure which is used to receive the jobs which uses docker+machine to create new instances. When there are no jobs, the orchestrator is the only vm running and can be on a minimal instance size.

{{{ this.coreContent }}}

## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/scalable-gitlab-ci?ref=v{{{ this.version }}}"

  project_prefix = "project"
  runner_tags    = ["project"]

  idle_count                = 0
  idle_time_seconds         = 300
  max_builds_per_machine    = 100
  gitlab_max_runners        = 3
  orchestrator_disk_size_gb = 50
  orchestrator_storage_type = "Standard_LRS"
  runner_storage_type       = "Premium_LRS"

  gitlab_token              = var.gitlab_token
  resource_group_name       = var.resource_group_name
  primary_location          = var.primary_location

  core_resource_group_name = var.core_resource_group_name
  container_registry_name  = var.container_registry_name
  subnet_service_endpoints = ["Microsoft.KeyVault"]
  trusted_cidr_ranges      = [var.cidr_range]
}
```

### Rebuilding CI box

Terraform has a concept of tainting resources to force a rebuild. If there is a problem with our CI box, we can `taint` it to force a rebuild. To do this, firstly identify the resource to taint by running the following command in the folder that contains your terraform state:

```bash
terraform state list
```

Pick the resource you want to taint (most likely `module.ci.azurerm_linux_virtual_machine.orchestrator`):

```bash
terraform taint <resource_in_state>
```

Then, reapply the terraform and the resource (and any dependencies) will be rebuilt.
