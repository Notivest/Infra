resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = merge(var.common_tags, { env = var.environment })
}
