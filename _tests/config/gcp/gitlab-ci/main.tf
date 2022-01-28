module gitlab_ci {
  source = "../../../../gcp/gitlab-ci"

  project_id             = "terraform-testing-317911"
  project_prefix         = "gitlab-ci-terratest"
  cidr_ranges            = []
  gcr_bucket_names       = []
  gcp_region             = "europe-west1"
  zones                  = ["europe-west1-c"]

  # The following are provided via test code
  runner_tags            = [var.runner_tag]
  encrypted_gitlab_token = var.encrypted_gitlab_token
  crypto_key_self_link   = var.crypto_key_self_link
}
