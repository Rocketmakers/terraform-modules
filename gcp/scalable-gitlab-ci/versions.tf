terraform {
  required_version = ">= 1.1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.27.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.4.0"
    }
  }
}
