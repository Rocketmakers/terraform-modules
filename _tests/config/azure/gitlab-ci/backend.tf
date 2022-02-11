terraform {
  # Config given in terratest code
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    tls = {
      source = "hashicorp/tls"
    }
    gitlab = {
      source = "gitlabhq/gitlab"
    }
  }
}

provider "azurerm" {
  features {}
}
