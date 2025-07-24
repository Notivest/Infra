resource "azurerm_container_registry" "this" {
  name                = "${var.acr_name_prefix}${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = merge(var.common_tags, { env = var.environment })
}
