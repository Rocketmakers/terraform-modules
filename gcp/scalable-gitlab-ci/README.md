# scalable-gitlab-ci

This module creates an orchestrator VM inside GCP which is used to receive the jobs which uses docker+machine to create new instances. When there are no jobs, the orchestrator is the only vm running and can be on a minimal instance size.

## Accessing a private Google Container Registry (GCR)

If your CI needs to push images to a private GCR then you need to provide the name of the bucket in the `gcr_bucket_names` variable:

```terraform
gcr_bucket_names = [
  "eu.artifacts.my-cool-project.appspot.com"
]
```

If you don't need to push to a private GCR then you can leave `gcr_bucket_names` empty.

### ⚠️ Use on a fresh project ⚠️

If your project has not yet pushed any container images to Google Container Registry then you will need to manually enable and push an image to the project before the `ci-box` module will work. This is because the CI box needs the GCR bucket to exist before terraform can grant permissions for the VM to access the bucket.

Follow the GCR [Quickstart](https: //cloud.google.com/container-registry/docs/quickstart) guide for how to do this.

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `cache_location` | The location of the cache bucket (see https://cloud.google.com/storage/docs/locations) | string |
| `cidr_ranges` | CIDR ranges allowed to access the runner instance | list(string) |
| `gcr_bucket_names` | Names of google container registry buckets that the runner instance has permission to access e.g. ["eu.artifacts.my-cool-project.appspot.com"] | list(string) |
| `gitlab_token` | Token used to register gitlab runner | string |
| `project_id` | Google Cloud project ID where the runner instance and related resources will be created | string |
| `project_prefix` | A prefix given to resource names related to the runner instance | string |
| `region` | The GCP region where VMs and related resources will be created. | string |
| `runner_machine_type` | Machine type of the runner vm | string |
| `runner_tags` | List of tags for gitlab runner (no tags will be added by default) | list(string) |
| `zone` | Google Cloud zone where instance should be placed | string |

## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
| `allow_stopping_for_update` | Allow the instance to stop when being updated | bool | true |
| `engine_install_url` | URL to use for engine installation through docker-machine | string | https://releases.rancher.com/install-docker/19.03.9.sh |
| `gitlab_max_runners` | The maximum number of VMs that will be created (one VM will run one job at a time). | number | 3 |
| `gitlab_runner_docker_image` | The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker) | string | docker:stable |
| `gitlab_runner_locked` | Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner. | bool | true |
| `gitlab_runner_version` | The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release) | string | latest |
| `image_name` | Google image name to base CI on | string | ubuntu-2004-focal-v20230302 |
| `image_project` | Google image project to base CI on | string | ubuntu-os-cloud |
| `name` | Main name of resources created | string | ci |
| `orchestrator_disk_size` | Size of orchestrator disk in GB | number | 50 |
| `orchestrator_idle_count` | Minimum number of VM's that will be left running when there is no demand for jobs | number | 0 |
| `orchestrator_idle_time` | Number of seconds for the machine to be in Idle State before it is destroyed | number | 300 |
| `orchestrator_machine_type` | Machine type of the orchestrator vm | string | f1-micro |
| `orchestrator_max_builds` | Maximum job count before machine is removed. | number | 100 |
| `runner_disk_size` | Size of runner disk in GB | number | 50 |
| `runner_machine_name` | Name of the machine. It must contain %s, which is replaced with a unique machine identifier. | string | auto-scale-%s |
| `service_account_roles` | The roles that should be assigned to the service account running the CI box | list(string) | ["roles/monitoring.metricWriter"] |
| `tags` | List of tags to enable ssh access | list(string) | ["ci","externalssh"] |
| `username` | Username for CI box | string | ci |

## Outputs

| name      | description                 |
| --------- | --------------------------- |
| `orchestrator_internal_ip_address` | Internal network IP address of the orchestrator instance |
| `orchestrator_private_key` | Private SSH key for the orchestrator instance |
| `orchestrator_public_ip_address` | Static IP address of the orchestrator instance |
| `orchestrator_public_key` | Public SSH key for the orchestrator instance |
| `orchestrator_service_account_email` | Google service account email for the orchestrator |
| `orchestrator_service_account_key` | Google service account key for the orchestrator |
| `orchestrator_username` | Username for orchestrator vm |
| `private_key` | [Deprecated] Private SSH key. Use orchestrator_private_key instead |
| `public_key` | [Deprecated] Public SSH key. Use orchestrator_public_key instead |
| `runner_service_account_email` | Google service account email for the runner(s) |
| `runner_service_account_key` | Google service account key for the runner(s) |
| `service_account_email` | [Deprecated] Google service account email. Use orchestrator_service_account_email instead |
| `service_account_key` | [Deprecated] Google service account key. Use orchestrator_service_account_key instead |
| `username` | [Deprecated] Username for CI box. Use orchestrator_username instead |

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
| `null` |  |
| `tls` | >= 3.4.0 |


## Example Use Cases

```terraform
provider "gitlab" {
  token = "secret-gitlab-token"
}

terraform {
  required_version = "1.1.6"

  backend "gcs" {
    bucket = "bucket"
    prefix = "infrastructure/project-ci/terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.22.0"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "3.14.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
  }
}

variable "project_id" {
  type        = string
  description = "Google Cloud project ID"
  default     = "project-id"
}

variable "gitlab_project_id" {
  type        = string
  description = "Gitlab project id"
  default     = "gitlab-project-id"
}

module "project-factory_project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "13.0.0"

  project_id = var.project_id
  activate_apis = [
    "cloudkms.googleapis.com",
    "containerregistry.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "secretmanager.googleapis.com"
  ]
  disable_services_on_destroy = false
  disable_dependent_services = false
}

data "gitlab_project" "this" {
  id = var.gitlab_project_id
}

resource "google_container_registry" "registry" {
  project  = var.project_id
  location = "EU"
}

module "ci" {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//gcp/scalable-gitlab-ci?ref=v3.0.0"

  project_id                = var.project_id
  zone                     = "europe-west1-b"
  region                    = "europe-west1"
  runner_tags               = [var.project_id]
  project_prefix            = var.project_id
  cidr_ranges               = ["212.139.176.173/32"]
  orchestrator_machine_type = "f1-micro"
  runner_machine_type       = "n2d-standard-2"
  service_account_roles = [
    "${var.project_id}=>roles/cloudkms.cryptoKeyDecrypter",
    "${var.project_id}=>roles/storage.admin",
    "${var.project_id}=>roles/viewer",
    "${var.project_id}=>roles/secretmanager.admin",
    "${var.project_id}=>roles/run.admin",
    "${var.project_id}=>roles/iam.serviceAccountUser",
    "${var.project_id}=>roles/monitoring.metricWriter",
  ]
  gitlab_token              = data.gitlab_project.this.runners_token
  gcr_bucket_names          = [google_container_registry.registry.id]
  gitlab_max_runners        = 3
  cache_location            = "EUROPE-WEST1"
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
