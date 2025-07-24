resource "random_password" "admin_pass" {
  length  = 20
  special = true
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.admin_user
  administrator_password = random_password.admin_pass.result
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  version                = "15"
  tags                   = merge(var.common_tags, { env = var.environment })
}

output "connection_string" {
  sensitive = true
  value = format(
    "postgres://%s:%s@%s.postgres.database.azure.com:5432/%s?sslmode=require",
    var.admin_user,
    random_password.admin_pass.result,
    azurerm_postgresql_flexible_server.this.name,
    var.db_name
  )
}
