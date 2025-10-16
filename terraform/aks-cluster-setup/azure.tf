terraform {
  backend "azurerm" {
    container_name       = "terraform-state"
    key                  = "prod.terraform.tfstate"
    resource_group_name  = var.resource_group_name
    storage_account_name = var.storage_account_name
  }
}
