module "gitlab_ci" {
  source = "../../../../gcp/gitlab-ci"

  project_id                = "terraform-testing-317911"
  project_prefix            = "gitlab-ci-terratest"
  cidr_ranges               = []
  gcr_bucket_names          = []
  gcp_region                = "europe-west1"
  zones                     = ["europe-west1-c"]
  runner_registration_token = data.gitlab_project.runner_token.runners_token

  # The following are provided via test code
  runner_tags    = [var.runner_tag]
  instance_count = var.instance_count
}

data "gitlab_project" "runner_token" {
  id = "33153506"
}
