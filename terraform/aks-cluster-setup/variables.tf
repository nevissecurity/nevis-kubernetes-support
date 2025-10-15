variable "resource_group_name" {
  description = "Name of the resource group you plan on deploying the resources."
}

variable "node_resource_group_name" {
  description = "The name of the Resource Group where the Kubernetes Nodes should exist."
}

variable "location" {
  description = "Location where to deploy the resources."
  default     = "West Europe"
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version, see: az aks get-versions --location 'West Europe' -o table"
}

variable "num_agents" {
  description = "Number of agents (should be at least 2 for productive use)"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM type for the cluster nodes."
}

variable "vm_disk_gb" {
  description = "Disk size of Node VM. Must be able to store all active Docker images"
  type        = number
  default     = 128
}

variable "max_pods" {
  description = "The maximum number of pods that can run on each agent"
  type        = number
  default     = 100
}

variable "db_server" {
  description = "Name of the Azure PostgreSQL database server"
}

variable "db_root_user" {
  description = "Username of the Azure PostgreSQL root user"
}

variable "registry_name" {
  description = "Name of the container registry to use"
}

variable "rbac_enabled" {
  description = "Whether to enable rbac or not"
}

variable "dns_prefix" {
  description = "A prefix that will be put in front of the auto-generated cluster ID: e.g., <prefix>-<number>.hcp.westeurope.azmk8s.io"
}

variable "vnet_subnet_cidr" {
  description = "Subnet in CIDR form where the AKS agents and Pods will be created. Must be a subnet of the virtual network and least a /24 network (recommended: /21)."
  default     = "10.1.0.0/21"
}

variable "service_cidr" {
  description = "The Network Range used by the Kubernetes service"
  default     = "10.100.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns)"
  default     = "10.100.0.10"
}

variable "admin_user" {
  description = "Admin user name of the Kubernetes cluster"
}

variable "subscription" {
  description = "The ID of your Azure subscription."
}

variable "storage_account_name" {
  description = "Name of your storage account. Should be globally unique and only contain alphanumeric characters."
}
