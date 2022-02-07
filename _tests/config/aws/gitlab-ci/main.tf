module gitlab_ci {
  source = "../../../../aws/gitlab-ci"

  availability_zones = ["a", "b"]
  cidr_ranges = [
    # Rocketmakers office
    "212.139.176.173",
  ]
  project_prefix          = "terratest"
  gitlab_token_secret_id  = "arn:aws:secretsmanager:eu-west-2:971573726931:secret:Terratest-X4XqSp"
  gitlab_token_secret_key = "gitlab-ci-key"

  # The following are provided via test code
  runner_tags    = [var.runner_tag]
  instance_count = var.instance_count
}
