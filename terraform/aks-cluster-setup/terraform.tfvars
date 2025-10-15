# ID of your Azure subscription
subscription=""

# Azure location where the resources will be created
# example: "West Europe"
location="West Europe"

# unique within Azure subscription
# example: nevis-cluster
resource_group_name=""

# The name of the Resource Group where the Kubernetes Nodes should exist.
# unique within Azure subscription
# example: nevis-cluster-nodes
node_resource_group_name=""

# globally unique and only lowercase alphanumeric characters allowed
# only lowercase alphanumeric characters, example: terraform33fef3fgs
storage_account_name=""

# name of the Kubernetes cluster, recommended to be the same as the resource group name
# example: nevis-cluster
cluster_name=""

# admin user of the Kubernetes cluster, can't be "admin"
# example k8sadmin
admin_user="k8sadmin"

# Kubernetes version to use on the cluster
# Default version could be outdated, command to list available versions:
# az aks get-versions --location 'West Europe' -o table
kubernetes_version="1.33.3"

# Name of the container registry to use
registry_name=""

# VM type for the cluster nodes. More info about possible options: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/compute-benchmark-scores
# Because of the way memory is reserved: https://docs.microsoft.com/en-us/azure/aks/concepts-clusters-workloads#resource-reservations
# a VM type with at least 16GB of memory is recommended. By default 2 nodes will be created, which later can be easily scaled up or down.
vm_size="Standard_D4s_v5"

# Number of agents (should be at least 2 for productive use)
num_agents=2

# Disk size of Node VM. Must be able to store all active Docker images
vm_disk_gb=128

# The maximum number of pods that can run on each agent
max_pods=100

# unique within Azure region
# example: nevisk8s, cluster url will have the following format:  <dns_prefix>-<number>.hcp.westeurope.azmk8s.io
dns_prefix=""

# option to enable role based access control, for more information visit: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
rbac_enabled="true"

# name of the database server, has to be unique
# example nevisk8spostgresqldb
db_server=""

# user name of the root user for the database server, can't be "root"
# example: dbroot
db_root_user=""
