terraform {
  # Config given in terratest code
  backend "gcs" {}
}

provider "google" {
  version = "2.20.0"
}
