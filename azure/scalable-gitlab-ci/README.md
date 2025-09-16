# scalable-azure-ci

This module creates an orchestrator VM inside Azure which is used to receive the jobs which uses docker+machine to create new instances. When there are no jobs, the orchestrator is the only vm running and can be on a minimal instance size.

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `container_registry_name` | Container registry name to enable access to | string |
| `core_resource_group_name` | The resource group containing the container registry | string |
| `gitlab_token` | Token used to register gitlab runner | string |
| `idle_time_seconds` | The maximum time a machine will remain in place without running any jobs. | number |
| `max_builds_per_machine` | The maximum number of jobs that will be run on a machine before it is removed. | number |
| `primary_location` | Main location to store everything (e.g. westeurope) | string |
| `project_prefix` | A prefix given to resource names related to the runner instance | string |
| `resource_group_name` | The name of the resource group in which to place resources | string |
| `runner_tags` | List of tags for gitlab runner, used to allow the runner to be selected for jobs. | list(string) |
| `subnet_service_endpoints` | The list of Service endpoints to associate with the subnet. | list(string) |
| `trusted_cidr_ranges` | CIDR ranges allowed to access CI instances via ssh | list(string) |

## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
| `cache_storage_min_tls_version` | The minimum supported TLS version for the storage account used by runners as a shared cache. | string | TLS1_2 |
| `cache_storage_replication_type` | The replication type of the storage account used by runners as a shared cache. | string | LRS |
| `cache_storage_tier` | The tier of the storage account used by runners as a shared cache. | string | Standard |
| `engine_install_url` | URL to use for engine installation through docker-machine | string | https://get.docker.com |
| `gitlab_max_runners` | The maximum number of VMs that will be created (one VM will run one job at a time). | number | 3 |
| `gitlab_runner_docker_image` | The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker) | string | docker:stable |
| `gitlab_runner_locked` | Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner. | bool | true |
| `gitlab_runner_version` | The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release) | string | latest |
| `idle_count` | The minimum number of runner machines that should be in place when there is no demand for jobs. | number | 0 |
| `image_config` | The details of the OS image used on the instance | object({<br />    publisher = string<br />    offer     = string<br />    sku       = string<br />    version   = string<br />  }) | {"offer":"0001-com-ubuntu-server-jammy","publisher":"Canonical","sku":"22_04-lts","version":"latest"} |
| `name` | Main name of resources created | string | ci |
| `network_address_space` | The address space that is used the virtual network. You can supply more than one address space. | list(string) | ["10.0.0.0/16"] |
| `network_subnet_address_prefixes` | The address prefixes of the CI boxes subnet. | list(string) | ["10.0.0.0/24"] |
| `orchestrator_disk_size_gb` | Size of disk in GB | number | 50 |
| `orchestrator_storage_type` | Storage type of the orchestrator VM. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS. | string | Standard_LRS |
| `orchestrator_vm_size` | Size of orchestrator VM to deploy | string | Standard_B1ls |
| `public_ip_allocation_method` | The allocation method for the public ip associated with the cluster | string | Static |
| `public_ip_sku` | The sku for the public ip associated with the orchestrator | string | Standard |
| `runner_machine_name` | Name of the machine. It must contain %s, which is replaced with a unique machine identifier. | string | auto-scale-%s |
| `runner_storage_type` | Storage type of the runner VM. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS. | string | Premium_LRS |
| `runner_vm_size` | Size of runner VM to deploy | string | Standard_B2s |
| `username` | Username for CI box | string | ci |

## Outputs

| name      | description                 |
| --------- | --------------------------- |
| `orchestrator_internal_ip_address` | Internal network IP address of the orchestrator instance |
| `orchestrator_private_key` | Private SSH key for the orchestrator instance |
| `orchestrator_public_ip_address` | Static IP address of the orchestrator instance |
| `orchestrator_public_key` | Public SSH key for the orchestrator instance |
| `orchestrator_username` | Username for orchestrator vm |
| `runner_client_id` | The client id for the runner |
| `runner_client_secret` | The client secret for the runner |
| `runner_principal_id` | The principal id for the runner |
| `subnet_id` | The id for the network subnet |

## Requirements

These are required by the module.

| name | version |
| ---- | ------- |
| `azuread` | >= 3.0.2 |
| `azurerm` | >= 4.9.0 |
| `terraform` | >= 1.1.6 |
| `tls` | >= 3.1.0 |

## Providers

These are the providers used by the module.

| name | version |
| ---- | ------- |
| `azuread` | >= 3.0.2 |
| `azurerm` | >= 4.9.0 |
| `terraform` |  |
| `tls` | >= 3.1.0 |


## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/scalable-gitlab-ci?ref=v3.8.1"

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
