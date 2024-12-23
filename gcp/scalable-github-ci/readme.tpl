# scalable-gcp-github-ci

This module creates a VM scale set of GitHub runners which scale up and down when jobs are being processed by the primary runner.

{{{ this.coreContent }}}

## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//gcp/scalable-github-ci?ref=v{{{ this.version }}}"

  ssh_cidr_ranges     = var.trusted_cidr_ranges
  gcr_bucket_names    = var.gcr_bucket_names
  github_api_token    = var.github_api_token
  github_organisation = "Rocketmakers/terraform-modules"
  machine_type        = "n2d-standard-2"
  project_id          = var.project_id
  project_prefix      = var.project_prefix
  region              = var.region
  zone                = var.zone

  min_instance_count = 1
  max_instance_count = 5
}
```
