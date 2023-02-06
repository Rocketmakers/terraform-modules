terraform {
  required_version = ">= 1.1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.97.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.33.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}
