# aws gitlab-ci

This module creates one or more VMs within AWS acting as gitlab-runners. Each runner will use the `--executor docker` and uses [Docker socket binding](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-socket-binding) to enable docker-in-docker (dind).

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `availability_zones` | The availability zones that the instance should be created in | list(string) |
| `project_prefix` | A prefix given to resource names related to the runner instance | string |
| `runner_registration_token` | The gitlab registration token that will be used to register the runner. | string |
| `runner_tags` | List of tags for gitlab runner, used to allow the runner to be selected for jobs. | list(string) |
| `ssh_cidr_ranges` | CIDR ranges allowed to access CI instances via ssh | list(string) |

## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
| `disk_size` | Size of disk in GB | number | 50 |
| `docker_prune_cron_schedule` | The schedule to use for pruning docker images to prevent disk space filling up. Default value is weekly on Sundays at 0400 UTC. | string | 0 4 * * 0 |
| `gitlab_runner_concurrency` | The maximum number of jobs that the runner will run concurrently | number | 3 |
| `gitlab_runner_docker_image` | The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker) | string | docker:stable |
| `gitlab_runner_locked` | Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner. | bool | true |
| `gitlab_runner_version` | The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release) | string | latest |
| `image_config` | A set of filters used to determine the OS image used on the instance. The latest matching image will be used. The default_username needs to be correct for the image that is resolved by the given filters. | object({<br />    owners                      = list(string)<br />    filter_names                = list(string)<br />    filter_virtualization_types = list(string)<br />    filter_root_device_types    = list(string)<br />    default_username            = string<br />  }) | {"default_username":"ubuntu","filter_names":["*ubuntu-bionic-18.04-amd64-server-*"],"filter_root_device_types":["ebs"],"filter_virtualization_types":["hvm"],"owners":["099720109477"]} |
| `instance_count` | The number of VM instances to create | number | 1 |
| `instance_type` | Instance type of the vm | string | t2.micro |
| `name` | Main name of resources created | string | ci |
| `tags` | Tags for aws resources | map(any) | {} |

## Outputs

| name      | description                 |
| --------- | --------------------------- |
| `internal_ip_addresses` | CI box network IP addresses |
| `ip_addresses` | CI static IP addresses |
| `private_key` | Private SSH key |
| `public_key` | Public SSH key |
| `username` | Username for CI box |

## Requirements

These are required by the module.

| name | version |
| ---- | ------- |
| `aws` | >= 4.1.0 |
| `terraform` | >= 1.1.6 |
| `tls` | >= 3.1.0 |

## Providers

These are the providers used by the module.

| name | version |
| ---- | ------- |
| `aws` | >= 4.1.0 |
| `tls` | >= 3.1.0 |


## Example Use Cases

```
module ci-box {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//aws/gitlab-ci?ref=v1.0.0"

  availability_zones         = var.availability_zone
  project_prefix             = local.project_prefix
  runner_registration_token  = var.runner_registration_token
  runner_tags                = var.runner_tags
  ssh_cidr_ranges            = var.ssh_cidr_ranges
  instance_type              = var.instance_type
}
```

### Rebuilding CI box

Terraform has a concept of tainting resources to force a rebuild. If there is a problem with our CI box, we can `taint` it to force a rebuild. To do this, firstly identify the resource to taint by running the following command in the folder that contains your terraform state:

```bash
terraform state list
```

Pick the resource you want to taint (most likely `module.gitlab-ci.aws_instance.ci`):

```bash
terraform taint <resource_in_state>
```

Then, reapply the terraform and the resource (and any dependencies) will be rebuilt.
