locals {
  name = "ghubscalableci"
}

module "scalable_gitlab_ci" {
  source = "../../../../gcp/scalable-github-ci"

  project_id          = var.project_id
  project_prefix      = local.name
  zone                = var.gcp_project_zone
  region              = var.gcp_project_region
  github_organisation = "TODO: Set this once we are in github"
  name                = local.name
  machine_type        = "n2d-standard-2"
  min_instance_count  = 1
  max_instance_count  = 3

  # The following are provided via test code
  github_api_token = var.github_api_token
  runner_labels    = [var.runner_label]
  ssh_cidr_ranges  = [var.cidr_range]
}
