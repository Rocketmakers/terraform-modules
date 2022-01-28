terraform {
  backend "gcs" {
    prefix = "gcp/gitlab-ci"
  }
}

provider "google" {
  version = "2.20.0"
}
