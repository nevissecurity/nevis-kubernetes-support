variable "subscription" {
  description = "The ID of your Azure subscription."
}

variable "storage_account_name" {
  description = "Name of your storage account. Should be globally unique and only contain alphanumeric characters."
}

variable "resource_group_name" {
  description = "Name of the resource group you plan on deploying the resources."
  default     = "@CLUSTER_NAME@"
}

variable "location" {
  description = "Location where to deploy the resources."
  default     = "West Europe"
}
