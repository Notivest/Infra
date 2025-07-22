resource "azurerm_resource_group" "core" {
  name     = "rg-dev-core"
  location = var.location
  tags     = { project = "notivest", env = terraform.workspace }
}
