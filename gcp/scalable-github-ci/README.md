# scalable-gcp-github-ci

This module creates a VM scale set of GitHub runners which scale up and down when jobs are being processed by the primary runner.

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `cidr_ranges` | CIDR ranges allowed to access the runner instance | list(string) |
| `gcr_bucket_names` | Names of google container registry buckets that the runner instance has permission to access e.g. ["eu.artifacts.my-cool-project.appspot.com"] | list(string) |
| `github_api_token` | The Github API token to support retrieving a runner registeration token | string |
| `github_organisation` | The Github organisation to use | string |
| `machine_type` | Machine type of the runner vm | string |
| `project_id` | Google Cloud project ID where the runner instance and related resources will be created | string |
| `project_prefix` | A prefix given to resource names related to the runner instance | string |
| `region` | The GCP region where VMs and related resources will be created. | string |
| `zone` | Google Cloud zone where instance should be placed | string |

## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
| `docker_prune_cron_schedule` | The schedule to use for pruning docker images to prevent disk space filling up. Default value is daily at 0400 UTC. | string | 0 4 * * * |
| `github_runner_version` | The version of github-runner to install | string | 2.317.0 |
| `image_name` | Google image name to base CI on | string | ubuntu-2004-focal-v20230302 |
| `image_project` | Google image project to base CI on | string | ubuntu-os-cloud |
| `max_instance_count` | The maximum number of VM instances to create | number | 1 |
| `min_instance_count` | The minimum number of VM instances to create | number | 1 |
| `name` | Main name of resources created | string | ci |
| `tags` | List of tags to enable ssh access | list(string) | ["ci","externalssh"] |
| `username` | Username for CI box | string | ci |


## Requirements

These are required by the module.

| name | version |
| ---- | ------- |
| `google` | >= 4.27.0 |
| `terraform` | >= 1.1.6 |
| `tls` | >= 3.4.0 |

## Providers

These are the providers used by the module.

| name | version |
| ---- | ------- |
| `google` | >= 4.27.0 |
| `tls` | >= 3.4.0 |


## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//gcp/scalable-github-ci?ref=v3.0.0"

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
