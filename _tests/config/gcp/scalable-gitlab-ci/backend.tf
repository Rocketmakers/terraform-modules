terraform {
  # Config given in terratest code
  backend "gcs" {}

  required_providers {
    gitlab = {
      source = "gitlabhq/gitlab"
    }
    google = {
      source = "hashicorp/google"
    }
  }
}
