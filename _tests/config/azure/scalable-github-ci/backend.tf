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
  }
}

provider "azurerm" {
  subscription_id = "68bb123f-6027-4e99-8ab0-a01fb16cdd79"
  features {}
}

provider "azuread" {
}
