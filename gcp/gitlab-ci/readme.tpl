# gitlab-ci

This module creates one or more VMs within GCP acting as gitlab-runners. Each runner will use the `--executor docker` and uses [Docker socket binding](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-socket-binding) to enable docker-in-docker (dind).

## Accessing a private Google Container Registry (GCR)

If your CI needs to push images to a private GCR then you need to provide the name of the bucket in the `gcr_bucket_names` variable:

```terraform
gcr_bucket_names = ["eu.artifacts.my-cool-project.appspot.com"]
```

If you don't need to push to a private GCR then you can leave `gcr_bucket_names` empty.

### ⚠️ Use on a fresh project ⚠️

If your project has not yet pushed any container images to Google Container Registry then you will need to manually enable and push an image to the project before the `ci-box` module will work. This is because the CI box needs the GCR bucket to exist before terraform can grant permissions for the VM to access the bucket.

Follow the GCR [Quickstart](https://cloud.google.com/container-registry/docs/quickstart) guide for how to do this.

{{{ this.coreContent }}}

## Example Use Cases

```
module "ci_box" {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//gcp/gitlab-ci?ref=v{{{ this.version }}}"

  instance_count             = var.instance_count
  gcp_region                 = var.gcp_region
  zones                      = var.zones
  project_id                 = var.project_id
  gcr_bucket_names           = var.gcr_bucket_names
  project_prefix             = var.project_prefix
  ssh_cidr_ranges            = var.trusted_ips
  runner_registration_token  = var.runner_registration_token
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
