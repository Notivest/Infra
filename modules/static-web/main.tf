resource "azurerm_static_site" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_size            = "Standard"
  tags                = merge(var.common_tags, { env = var.environment })
}