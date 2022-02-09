module gitlab_ci {
  source = "../../../../gcp/gitlab-ci"

  project_id             = "terraform-testing-317911"
  project_prefix         = "gitlab-ci-terratest"
  cidr_ranges            = []
  gcr_bucket_names       = []
  gcp_region             = "europe-west1"
  zones                  = ["europe-west1-c"]
  encrypted_gitlab_token = "CiQA8kio5uT0OO1WRtZMB6V9zrDpLcFF92VrK6tLLY7XOr4TG94SPQD9t8BCTtEelpIo1iTjjtDH5Vm3x6lE0ftB/9l/cex5zaYUWKr8Gpw3AgbNZIkE/DV1n6ZCqg6E3D0ee7o="
  crypto_key_self_link   = "projects/rocketmakers-developers/locations/europe-west2/keyRings/rocketmakers-secrets/cryptoKeys/rocketmakers-secrets"

  # The following are provided via test code
  runner_tags    = [var.runner_tag]
  instance_count = var.instance_count
}
