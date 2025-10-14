terraform {
  backend "azurerm" {
    container_name       = "terraform-state"
    key                  = "prod.terraform.tfstate"
  }
}
