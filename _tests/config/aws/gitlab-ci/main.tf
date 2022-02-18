module "gitlab_ci" {
  source = "../../../../aws/gitlab-ci"

  availability_zones = ["a", "b"]
  cidr_ranges = [
    # Rocketmakers office
    "212.139.176.173/32",
  ]
  project_prefix            = "terratest"
  runner_registration_token = data.gitlab_project.runner_token.runners_token

  # The following are provided via test code
  runner_tags    = [var.runner_tag]
  instance_count = var.instance_count
}

data "gitlab_project" "runner_token" {
  id = "33153506"
}
