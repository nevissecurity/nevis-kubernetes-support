resource "azurerm_postgresql_flexible_server_configuration" "client_encoding" {
  server_id = azurerm_postgresql_flexible_server.db_server.id
  name      = "client_encoding"
  value     = "UTF8"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
  server_id = azurerm_postgresql_flexible_server.db_server.id
  name      = "log_statement"
  value     = "all"
}

resource "azurerm_postgresql_flexible_server_configuration" "default_transaction_isolation" {
  server_id = azurerm_postgresql_flexible_server.db_server.id
  name      = "default_transaction_isolation"
  value     = "read committed"
}

resource "azurerm_postgresql_flexible_server_configuration" "timezone" {
  server_id = azurerm_postgresql_flexible_server.db_server.id
  name      = "timezone"
  value     = "UTC"
}

resource "azurerm_postgresql_flexible_server_configuration" "statement_timeout" {
  server_id = azurerm_postgresql_flexible_server.db_server.id
  name      = "statement_timeout"
  value     = "1800000" # 1800s in ms
}