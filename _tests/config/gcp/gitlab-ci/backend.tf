terraform {
  # Config given in terratest code
  backend "gcs" {}

  required_providers {
    gitlab = {
      source = "gitlabhq/gitlab"
    }
  }
}

provider "google" {
  version = "2.20.0"
}
