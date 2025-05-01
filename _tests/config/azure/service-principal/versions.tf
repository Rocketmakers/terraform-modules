terraform {
  required_version = ">= 1.1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0.2"
    }
  }
}

provider "azurerm" {
  subscription_id = "68bb123f-6027-4e99-8ab0-a01fb16cdd79"
  features {}
}

provider "azuread" {
}
