terraform {
  # Config given in terratest code
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}
