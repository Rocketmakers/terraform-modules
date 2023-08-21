# gitlab-ci

This module creates one or more VMs within Azure acting as gitlab-runners. Each runner will use the `--executor docker` and uses [Docker socket binding](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-socket-binding) to enable docker-in-docker (dind).

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `container_registry_name` | Container registry name to enable access to | string |
| `key_vault_name` | Azure key vault id that jobs on the runner will need to access. | string |
| `primary_location` | Main location to store everything (e.g. westeurope) | string |
| `project_prefix` | A prefix given to resource names related to the runner instance | string |
| `resource_group_name` | The name of the resource group in which to place resources | string |
| `runner_registration_token` | The gitlab registration token that will be used to register the runner. | string |
| `runner_tags` | List of tags for gitlab runner, used to allow the runner to be selected for jobs. | list(string) |
| `ssh_cidr_ranges` | CIDR ranges allowed to access CI instances via ssh | list(string) |

## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
| `disk_size` | Size of disk in GB | number | 50 |
| `docker_prune_cron_schedule` | The schedule to use for pruning docker images to prevent disk space filling up. Default value is daily at 0400 UTC. | string | 0 4 * * * |
| `gitlab_runner_concurrency` | The maximum number of jobs that the runner will run concurrently | number | 3 |
| `gitlab_runner_docker_image` | The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker) | string | docker:stable |
| `gitlab_runner_locked` | Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner. | bool | true |
| `gitlab_runner_version` | The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release) | string | latest |
| `image_config` | The details of the OS image used on the instance | object({<br />    publisher = string<br />    offer     = string<br />    sku       = string<br />    version   = string<br />  }) | {"offer":"0001-com-ubuntu-server-focal","publisher":"Canonical","sku":"20_04-lts","version":"latest"} |
| `instance_count` | The number of VM instances to create | number | 1 |
| `name` | Main name of resources created | string | ci |
| `network_address_space` | The address space that is used the virtual network. You can supply more than one address space. | list(string) | ["10.0.0.0/16"] |
| `network_subnet_address_prefixes` | The address prefixes of the CI boxes subnet. | list(string) | ["10.0.0.0/24"] |
| `public_ip_allocation_method` | The allocation method for the public ip associated with the cluster | string | Static |
| `public_ip_sku` | The sku for the public ip associated with the cluster | string | Standard |
| `username` | Username for CI box | string | ci |
| `vm_size` | Size of VM to deploy | string | Standard_B2s |

## Outputs

| name      | description                 |
| --------- | --------------------------- |
| `internal_ip_addresses` | Internal network IP address of each instance |
| `ip_addresses` | CI Box public IP address |
| `private_key` | CI Box private key - used for SSH |
| `public_key` | Public SSH key |
| `service_principal_ids` | The ids of the underlying service principal accounts |
| `username` | Username for CI box |

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
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/gitlab-ci?ref=v2.1.3"

  container_registry_name   = var.container_registry_name
  key_vault_name            = var.key_vault_name
  primary_location          = var.primary_location
  project_prefix            = var.project_prefix
  resource_group_name       = var.resource_group_name
  runner_registration_token = var.runner_registration_token_name
  runner_tags               = var.runner_tags_name
  ssh_cidr_ranges           = var.ssh_cidr_ranges
}
```

### Rebuilding CI box

Terraform has a concept of tainting resources to force a rebuild. If there is a problem with our CI box, we can `taint` it to force a rebuild. To do this, firstly identify the resource to taint by running the following command in the folder that contains your terraform state:

```bash
terraform state list
```

Pick the resource you want to taint (most likely `module.ci.azurerm_linux_virtual_machine.ci_box`):

```bash
terraform taint <resource_in_state>
```

Then, reapply the terraform and the resource (and any dependencies) will be rebuilt.
