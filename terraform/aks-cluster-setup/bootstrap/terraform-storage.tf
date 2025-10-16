terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.9.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription
  features { }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "terraform" {
  name                      = var.storage_account_name
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
}

resource "azurerm_storage_container" "terraform" {
  name                  = "terraform-state"
  storage_account_id    = azurerm_storage_account.terraform.id
  container_access_type = "private"
}

output "storage_account_name" {
  value = azurerm_storage_account.terraform.name
}
