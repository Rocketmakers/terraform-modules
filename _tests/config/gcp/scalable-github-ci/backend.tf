terraform {
  # Config given in terratest code
  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.27.0" // TODO: Upgrade to latest version
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.gcp_project_zone
  zone    = var.gcp_project_region
}
