terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13"
    }
  }
  backend "azurerm" {}

}

provider "azapi" {
  subscription_id = var.subscription_id_app_lz
}

provider "azurerm" {
  subscription_id     = var.subscription_id_app_lz
  storage_use_azuread = true
  use_msi             = true
  features {}
}

provider "azurerm" {
  alias           = "connectivity"
  subscription_id = var.subscription_id_connectivity
  features {}
}
