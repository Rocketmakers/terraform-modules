terraform {
  # Config given in terratest code
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azuread = {
      source = "hashicorp/azuread"
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

provider "azuread" {
}
