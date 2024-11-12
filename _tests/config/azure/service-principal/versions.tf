terraform {
  required_version = ">= 1.1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.97.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0.2"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}
