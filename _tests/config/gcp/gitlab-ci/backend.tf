terraform {
  backend "gcs" {
    # TODO: Try partial config for the backend bucket
    bucket = "rocketmakers-terratest"
    prefix = "gcp/gitlab-ci"
  }
}

provider "google" {
  version = "2.20.0"
}
