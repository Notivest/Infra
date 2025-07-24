resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_env_id
  revision_mode                = var.revision_mode
  tags                         = var.common_tags

  dynamic "secret" {
    for_each = var.secret_map
    content {
      name  = secret.key
      value = secret.value
    }
  }

  registry {
    server   = var.registry_server
    identity = var.identity_id
  }

  template {
    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_map
        content {
          name        = env.key
          secret_name = env.key
        }
      }
    }
  }
}