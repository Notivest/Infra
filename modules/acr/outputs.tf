output "login_server" { value = azurerm_container_registry.this.login_server }
output "id" {
  description = "Resource ID del ACR"
  value       = azurerm_container_registry.this.id
}