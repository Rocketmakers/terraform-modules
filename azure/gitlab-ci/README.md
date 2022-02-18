# gitlab-ci

Creates a CI runner for use within gitlab

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `container_registry_name` | Container registry name to enable access to | string |
| `key_vault_name` | Azure key vault id that jobs on the runner will need to access. | string |
| `primary_location` | Main location to store everything (e.g. westeurope) | string |
| `project_name` | Project name | string |
| `resource_group` | Resource group | string |
| `runner_registration_token` | The gitlab registration token that will be used to register the runner. | string |
| `whitelist` | CIDR whitelist of entities allowed to access resource | list(string) |

## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
| `docker_prune_cron_schedule` | The schedule to use for pruning docker images to prevent disk space filling up. Default value is weekly on Sundays at 0400 UTC. | string | 0 4 * * 0 |
| `gitlab_runner_concurrency` | The maximum number of jobs that the runner will run concurrently | number | 2 |
| `gitlab_runner_docker_image` | The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker) | string | docker:stable |
| `gitlab_runner_locked` | Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner. | bool | true |
| `gitlab_runner_version` | The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release) | string | latest |
| `instance_count` | The number of VM instances to create | number | 1 |
| `network_address_space` | The address space that is used the virtual network. You can supply more than one address space. | list(string) | ["10.0.0.0/16"] |
| `network_subnet_address_prefix` | The address prefix of the CI boxes subnet. | string | 10.0.0.0/24 |
| `public_ip_allocation_method` | The allocation method for the public ip associated with the cluster | string | Static |
| `public_ip_sku` | The sku for the public ip associated with the cluster | string | Standard |
| `runner_tags` | List of tags for gitlab runner | list(string) | ["rocketmakers","docker"] |
| `vm_size` | Size of VM to deploy | string | Standard_B2s |

## Outputs

| name      | description                 |
| --------- | --------------------------- |
| `ip_addresses` | CI Box public IP address |
| `private_key` | CI Box private key - used for SSH |

## Requirements

These are required by the module.

| name | version |
| ---- | ------- |
| `azurerm` | >= 2.97.0 |
| `terraform` | >= 1.1.6 |
| `tls` | >= 3.1.0 |

## Providers

These are the providers used by the module.

| name | version |
| ---- | ------- |
| `azurerm` | >= 2.97.0 |
| `tls` | >= 3.1.0 |


## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/ci?ref=v0.8.0"

  resource_group = data.terraform_remote_state.core.outputs.resource_group_name
  project_name   = var.project_name
  key_vault_name = data.terraform_remote_state.core.outputs.key_vault_name
}
```