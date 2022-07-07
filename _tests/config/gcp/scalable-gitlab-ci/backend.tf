terraform {
  backend "gcs" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
    }
    null = {
      source  = "hashicorp/null"
    }
  }
}
