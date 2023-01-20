# scalable-gitlab-ci

This module creates an orchestrator VM inside Azure which is used to receive the jobs which uses docker+machine to create new instances. When there are no jobs, the orchestrator is the only vm running and can be on a minimal instance size.

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `container_registry_name` | Container registry name to enable access to | string |
| `core_resource_group_name` | The resource group containing the container registry and key vault | string |
| `disk_size_gb` | Size of disk in GB | number |
| `gitlab_runner_concurrency` | The maximum number of machines that will be in place at any one time (one job per machine) | number |
| `idle_count` | The minimum number of runner machines that should be in place when there is no demand for jobs. | number |
| `idle_time_seconds` | The maximum time a machine will remain in place without running any jobs. | number |
| `key_vault_name` | Azure key vault id that jobs on the runner will need to access. | string |
| `max_builds_per_machine` | The maximum number of jobs that will be run on a machine before it is removed. | number |
| `primary_location` | Main location to store everything (e.g. westeurope) | string |
| `project_prefix` | A prefix given to resource names related to the runner instance | string |
| `registration_token_key_vault_id` | The id of the azure key vault containing the token used to register the gitlab runner | string |
| `registration_token_secret_name` | The name of the azure key vault secret containing the token used to register the gitlab runner | string |
| `resource_group_name` | Resource group | string |
| `runner_tags` | List of tags for gitlab runner, used to allow the runner to be selected for jobs. | list(string) |
| `subnet_service_endpoints` | The list of Service endpoints to associate with the subnet. | list(string) |
| `trusted_cidr_ranges` | CIDR ranges allowed to access CI instances via ssh | list(string) |

## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
| `engine_install_url` | URL to use for engine installation through docker-machine | string | https://releases.rancher.com/install-docker/19.03.9.sh |
| `gitlab_runner_docker_image` | The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker) | string | docker:stable |
| `gitlab_runner_locked` | Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner. | bool | true |
| `gitlab_runner_version` | The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release) | string | latest |
| `image_config` | The details of the OS image used on the instance | object({<br />    publisher = string<br />    offer     = string<br />    sku       = string<br />    version   = string<br />  }) | {"offer":"UbuntuServer","publisher":"Canonical","sku":"18.04-LTS","version":"latest"} |
| `name` | Main name of resources created | string | ci |
| `network_address_space` | The address space that is used the virtual network. You can supply more than one address space. | list(string) | ["10.0.0.0/16"] |
| `network_subnet_address_prefixes` | The address prefixes of the CI boxes subnet. | list(string) | ["10.0.0.0/24"] |
| `orchestrator_vm_size` | Size of orchestrator VM to deploy | string | Standard_B1ls |
| `public_ip_allocation_method` | The allocation method for the public ip associated with the cluster | string | Static |
| `public_ip_sku` | The sku for the public ip associated with the cluster | string | Standard |
| `runner_vm_size` | Size of runner VM to deploy | string | Standard_B2s |
| `username` | Username for CI box | string | ci |

## Outputs

| name      | description                 |
| --------- | --------------------------- |
| `internal_ip_addresses` | Internal network IP address of each instance |
| `ip_addresses` | CI Box public IP address |
| `private_key` | CI Box private key - used for SSH |
| `public_key` | Public SSH key |
| `runner_client_id` | The client id for the runner |
| `runner_client_secret` | The client secret for the runner |
| `runner_principal_id` | The principal id for the runner |
| `subnet_id` | The id for the network subnet |
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
| `azuread` |  |
| `azurerm` | >= 2.97.0 |
| `null` |  |
| `tls` | >= 3.1.0 |


## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/scalable-gitlab-ci?ref=v1.1.2"

  project_prefix = "project"
  runner_tags    = ["project"]

  idle_count                = 0
  idle_time_seconds         = 300
  max_builds_per_machine    = 100
  gitlab_runner_concurrency = 3
  disk_size_gb              = 50

  registration_token_secret_name  = "gitlab-runner-registration-token"
  registration_token_key_vault_id = dependency.key_vault.outputs.key_vault_id
  resource_group_name             = dependency.resource_group_ci.outputs.resource_group_name
  primary_location                = dependency.resource_group_ci.outputs.resource_group_location

  core_resource_group_name = dependency.resource_group_core.outputs.resource_group_name
  container_registry_name  = dependency.container_registry.outputs.registry_name
  key_vault_name           = dependency.key_vault.outputs.key_vault_name
  subnet_service_endpoints = ["Microsoft.KeyVault"]
}
```

### Rebuilding CI box

Terraform has a concept of tainting resources to force a rebuild. If there is a problem with our CI box, we can `taint` it to force a rebuild. To do this, firstly identify the resource to taint by running the following command in the folder that contains your terraform state:

```bash
terraform state list
```

Pick the resource you want to taint (most likely `module.ci_box.aws_instance.ci`):

```bash
terraform taint <resource_in_state>
```

Then, reapply the terraform and the resource (and any dependencies) will be rebuilt.
