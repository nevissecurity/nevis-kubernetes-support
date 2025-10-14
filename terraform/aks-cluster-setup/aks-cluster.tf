resource "azurerm_virtual_network" "vnet" {
  name                = "${var.cluster_name}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.1.0.0/16"]
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rgroup" {
  name = var.resource_group_name
}

resource "tls_private_key" "agents_admin_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.cluster_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [ var.vnet_subnet_cidr ]
}

resource "azurerm_role_assignment" "aks_subnet_admin" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.cluster_name}-vnet/subnets/${azurerm_subnet.aks_subnet.name}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.rgroup.location
  resource_group_name = var.resource_group_name
  node_resource_group = var.node_resource_group_name
  dns_prefix         = var.dns_prefix
  kubernetes_version = var.kubernetes_version
  role_based_access_control_enabled = var.rbac_enabled

  linux_profile {
    admin_username = var.admin_user

    ssh_key {
      key_data = tls_private_key.agents_admin_ssh_key.public_key_openssh
    }
  }

  default_node_pool {
    name               = "default"
    node_count         = var.num_agents
    vm_size            = var.vm_size
    os_disk_size_gb    = var.vm_disk_gb
    vnet_subnet_id     = azurerm_subnet.aks_subnet.id
    max_pods           = var.max_pods
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    load_balancer_sku  = "standard"
    load_balancer_profile {
      outbound_ip_address_ids = [ azurerm_public_ip.aks_egress_ip.id ]
    }
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
  }

  tags = {
    ManagedBy = "Terraform"
  }
}

// kubernetes load balancer steals the first static IP:
resource "azurerm_public_ip" "aks_egress_ip" {
  name = "aks-egress-ip"
  location = var.location
  resource_group_name = var.resource_group_name
  sku = "Standard" // basic has no SLA: https://docs.microsoft.com/en-us/azure/load-balancer/skus
  allocation_method = "Static" // Dynamic cannot be used
}

resource "azurerm_role_assignment" "public_ip_access_aks_cluster_egress" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = azurerm_public_ip.aks_egress_ip.id
}

output "aks_cluster_resource_group" {
  value = var.resource_group_name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks_cluster_egress_ip" {
  value = azurerm_public_ip.aks_egress_ip.ip_address
}
