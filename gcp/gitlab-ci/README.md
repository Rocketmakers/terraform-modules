# gitlab-ci

This module creates one or more VMs acting as gitlab-runners. Each runner will use the `--executor docker` and uses [Docker socket binding](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-socket-binding) to enable docker-in-docker (dind).

## Accessing a private Google Container Registry (GCR)

If your CI needs to push images to a private GCR then you need to provide the name of the bucket in the `gcr-bucket-names` variable:

```terraform
gcr-bucket-names = ["eu.artifacts.my-cool-project.appspot.com"]
```

If you don't need to push to a private GCR then you can leave `gcr-bucket-names` empty (this is the default).

### ⚠️ Use on a fresh project ⚠️

If your project has not yet pushed any container images to Google Container Registry then you will need to manually enable and push an image to the project before the `ci-box` module will work. This is because the CI box needs the GCR bucket to exist before terraform can grant permissions for the VM to access the bucket.

Follow the GCR [Quickstart](https://cloud.google.com/container-registry/docs/quickstart) guide for how to do this.

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `cidr_ranges` | CIDR ranges allowed to access the runner instance | list(string) |
| `crypto_key_self_link` | Self link for the KMS crypto key | string |
| `encrypted_gitlab_token` | Base64 encoded KMS encrypted gitlab token | string |
| `gcp_region` | The Google Cloud region where resources should be created | string |
| `gcr_bucket_names` | Names of google container registry buckets that the runner instance has permission to access e.g. ["eu.artifacts.my-cool-project.appspot.com"] | list(string) |
| `project_id` | Google Cloud project ID where the runner instance and related resources will be created | string |
| `project_prefix` | A prefix given to resource names related to the runner instance | string |
| `runner_tags` | List of tags for gitlab runner (no tags will be added by default) | list(string) |
| `zones` | List of Google Cloud zones where instances should be placed (the zones will be used in a round-robin strategy when creating instances) | list(string) |

## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
| `allow_stopping_for_update` | Allow the instance to stop when being updated | bool | true |
| `crontab_file` | Name of crontab file | string | /var/spool/cron/crontabs/ci |
| `disable_compute_on_destroy` | Whether to disable GCP Compute engine and/or dependent services when the module is destroyed | object({<br />    disable_service            = bool<br />    disable_dependent_services = bool<br />  }) | {"disable_dependent_services":false,"disable_service":false} |
| `disk_size` | Size of disk in GB | number | 50 |
| `docker_prune_cron_schedule` | The schedule to use for pruning docker images to prevent disk space filling up. Default value is weekly on Sundays at 0400 UTC. | string | 0 4 * * 0 |
| `gitlab_runner_concurrency` | The maximum number of jobs that the runner will run concurrently | number | 3 |
| `gitlab_runner_docker_image` | The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker) | string | docker:stable |
| `gitlab_runner_locked` | Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner. | bool | true |
| `gitlab_runner_version` | The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release) | string | latest |
| `image_name` | Google image name to base CI on | string | ubuntu-1804-bionic-v20190628 |
| `image_project` | Google image project to base CI on | string | ubuntu-os-cloud |
| `instance_count` | The number of VM instances to create | number | 1 |
| `machine_type` | Machine type of the vm | string | f1-micro |
| `name` | Main name of resources created | string | ci |
| `service_account_roles` | The roles that should be assigned to the service account running the CI box | list(string) | ["roles/monitoring.metricWriter"] |
| `service_account_scopes` | The scopes that should be supported by the CI service account | list(string) | ["storage-rw","monitoring-write"] |
| `tags` | List of tags to enable ssh access | list(string) | ["ci","externalssh"] |
| `username` | Username for CI box | string | ci |

## Outputs

| name      | description                 |
| --------- | --------------------------- |
| `addresses` | Static IP address of each instance |
| `internal_addresses` | Internal network IP address of each instance |
| `private_key` | Private SSH key |
| `public_key` | Public SSH key |
| `username` | Username for CI box |

## Requirements

These are required by the module.

| name | version |
| ---- | ------- |
| `google` | >= 2.20 |
| `terraform` | >= 0.13 |
| `tls` | >= 2.2 |

## Providers

These are the providers used by the module.

| name | version |
| ---- | ------- |
| `google` | >= 2.20 |
| `tls` | >= 2.2 |


## Example Use Cases

```
module ci_box {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//gcp/ci-box?ref=v3.0.0"

  instance_count             = var.instance_count
  zones                      = var.zones
  project_id                 = var.project_id
  gcr_bucket_names           = var.gcr_bucket_names
  project_prefix             = var.project_prefix
  cidr_ranges                = module.trusted_ips.cidrs
  encrypted_gitlab_token     = var.encrypted_gitlab_token
  crypto_key_self_link       = var.crypto_key_self_link
  machine_type               = var.machine_type
  runner_tags                = var.runner_tags
  gitlab_runner_concurrency  = var.runner_concurrency
  gitlab_runner_docker_image = var.runner_docker_image
  gitlab_runner_locked       = var.runner_locked
}
```

### Rebuilding CI box

Terraform has a concept of tainting resources to force a rebuild. If there is a problem with our CI box, we can `taint` it to force a rebuild. To do this, firstly identify the resource to taint by running the following command in the folder that contains your terraform state:

```bash
terraform state list
```

Pick the resource you want to taint (most likely `module.ci_box.google_compute_instance.ci_box`):

```bash
terraform taint <resource_in_state>
```

Then, reapply the terraform and the resource (and any dependencies) will be rebuilt.
