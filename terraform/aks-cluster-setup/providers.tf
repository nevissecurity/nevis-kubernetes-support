terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.9.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.6"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription
  features { }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config_host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config_client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config_client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config_cluster_ca_certificate)
}
