resource "azurerm_container_registry" "registry" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku = "Basic"
}
 
resource "azurerm_role_assignment" "registry_access_aks_cluster" {
  principal_id = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
 
  role_definition_name = "Reader"
  scope                = azurerm_container_registry.registry.id
}
