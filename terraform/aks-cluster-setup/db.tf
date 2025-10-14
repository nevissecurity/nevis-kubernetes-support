# Generate a random password for the PostgreSQL admin
resource "random_string" "db_server_admin_password" {
  length  = 32
  special = false
}

resource "azurerm_postgresql_flexible_server" "db_server" {
  name                = var.db_server
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login    = var.db_root_user
  administrator_password = random_string.db_server_admin_password.result
  version                = "16"

  sku_name    = "GP_Standard_D2s_v3"
  storage_mb  = 32768
  backup_retention_days = 7

  public_network_access_enabled = false
  auto_grow_enabled             = true
}

# Output the generated password
output "db_password" {
  value = random_string.db_server_admin_password.result
  sensitive = true
}
