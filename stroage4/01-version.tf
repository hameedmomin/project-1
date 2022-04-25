terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name   = azurerm_resource_group.storage.name
    storage_account_name  = azurerm_storage_account.new-sa.name
    container_name        = "${azurerm_storage_container.backend.name}"
    key                   = "project-1-eastus2-terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}