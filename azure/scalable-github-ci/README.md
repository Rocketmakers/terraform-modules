# scalable-azure-github-ci

This module creates a VM scale set of GitHub runners which scale up and down when jobs are being processed by the primary runner.

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `autoscaler_webhook_repo_name` | The name of the repository to register the webhook against | string |
| `container_registry_name` | Container registry name to enable access to | string |
| `container_registry_resource_group_name` | The name of the resource group the container registry can be found in | string |
| `github_api_token` | The Github API token to support retrieving a runner registration token | string |
| `github_organisation` | The name of the Github organisation to use (e.g. Rocketmakers), if registering against an organisation, or the name of the repository (e.g. Rocketmakers/terraform-modules), if registering against a single repository | string |
| `primary_location` | Main location to store everything (e.g. westeurope) | string |
| `resource_group_name` | The name of the resource group in which to place resources | string |
| `ssh_cidr_ranges` | CIDR ranges allowed to access CI instances via ssh | list(string) |
| `subnet_service_endpoints` | The list of Service endpoints to associate with the subnet. | list(string) |
| `vm_size` | Size of VM to deploy | string |

## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
| `autoscaler_cpu` | The amount of CPU to allocate to the autoscaler container | number | 0.25 |
| `autoscaler_log_level` | The log level to use | string | Information |
| `autoscaler_log_workspace_retention_in_days` | The retention period in days for the Log Analytics workspace used by the autoscaler | number | 30 |
| `autoscaler_log_workspace_sku` | The SKU of the Log Analytics workspace to use for the autoscaler | string | PerGB2018 |
| `autoscaler_memory` | The amount of memory to allocate to the autoscaler container in GB | string | 0.5Gi |
| `autoscaler_ms_delay_before_handling_webhook` | The delay in milliseconds before handling a relevant github action webhook event | number | 2000 |
| `autoscaler_revision_mode` | The revision mode for the autoscaler | string | Single |
| `autoscaler_structured_logs` | Whether to enable structured logging in the autoscaler | bool | true |
| `autoscaler_version` | The version of the autoscaler to use | string | 1.0.4 |
| `autoscaler_webhook_enabled` | Whether to enable the GitHub webhook for the autoscaler | bool | true |
| `autoscaler_webhook_events` | The list of GitHub events that should trigger the webhook | list(string) | ["workflow_job"] |
| `autoscaler_webhook_path` | The path to use for the GitHub webhook endpoint | string | /webhook |
| `autoscaler_workload_profile_type` | The workload profile type for the autoscaler | string | Consumption |
| `disk_size` | Size of disk in GB | number | 50 |
| `disk_storage_account_type` | The storage account type to use for the OS disk (Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_LRS, Premium_ZRS) | string | StandardSSD_LRS |
| `docker_install_script_url` | The URL to the Docker installation script | string | https://get.docker.com/ |
| `encryption_at_host_enabled` | Determines if encryption at host is enabled for the machine | bool | true |
| `github_runner_version` | The version of github-runner to install | string | 2.321.0 |
| `image_config` | The details of the OS image used on the instance | object({<br />    publisher = string<br />    offer     = string<br />    sku       = string<br />    version   = string<br />  }) | {"offer":"0001-com-ubuntu-server-jammy","publisher":"Canonical","sku":"22_04-lts","version":"latest"} |
| `max_instance_count` | The maximum number of VM instances to create | number | 1 |
| `name` | Main name of resources created | string | ci |
| `network_address_space` | The address space that is used the virtual network. You can supply more than one address space. | list(string) | ["10.0.0.0/16"] |
| `network_subnet_address_prefixes` | The address prefixes of the CI boxes subnet. | list(string) | ["10.0.0.0/24"] |
| `runner_labels` | The labels to assign to the runner | list(string) | [] |
| `scale_in_rule` | The rule to use for scaling in | string | OldestVM |
| `username` | Username for CI box | string | ci |

## Outputs

| name      | description                 |
| --------- | --------------------------- |
| `autoscaler_public_url` | The public URL of the autoscaler |
| `github_webhook_secret` | The secret supplied in all GitHub webhook requests |
| `private_key` | CI Box private key - used for SSH |
| `public_key` | Public SSH key |
| `service_principal_ids` | The ids of the underlying service principal accounts |
| `subnet_id` | The id of the subnet the CI runner is assigned to |
| `username` | Username for CI box |
| `virtual_machine_scale_set_id` | The id of the virtual machine scale set for the CI runner |
| `virtual_network_id` | The id of the virtual network associated with the CI runner |
| `virtual_network_name` | The name of the virtual network associated with the CI runner |

## Requirements

These are required by the module.

| name | version |
| ---- | ------- |
| `azurerm` | >= 3.108.0 |
| `github` | >= 6.6.0 |
| `terraform` | >= 1.1.6 |
| `tls` | >= 4.0.5 |

## Providers

These are the providers used by the module.

| name | version |
| ---- | ------- |
| `azurerm` | >= 3.108.0 |
| `github` | >= 6.6.0 |
| `random` |  |
| `terraform` |  |
| `tls` | >= 4.0.5 |


## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/scalable-github-ci?ref=v3.8.2"

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
