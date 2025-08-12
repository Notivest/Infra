############################
# ETIQUETAS COMUNES
############################
locals {
  common_tags = {
    project = "notivest"
    owner   = "platform-team"
  }
}

############################
# MÓDULOS BASE
############################
module "rg_core" {
  source      = "../../modules/resource-group"
  name        = "rg-${var.environment}-core"
  location    = var.location
  environment = var.environment
  common_tags = local.common_tags
}

module "acr" {
  source              = "../../modules/acr"
  acr_name_prefix     = "notivest"
  resource_group_name = module.rg_core.name
  location            = var.location
  environment         = var.environment
  common_tags         = local.common_tags
}

############################
# CAE & IDENTITY
############################
resource "azurerm_container_app_environment" "capp_env" {
  name                = "capp-env-${var.environment}"
  location            = var.location
  resource_group_name = module.rg_core.name
}

resource "azurerm_user_assigned_identity" "capp_identity" {
  name                = "capp-id-${var.environment}"
  location            = var.location
  resource_group_name = module.rg_core.name
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_user_assigned_identity.capp_identity.principal_id
  role_definition_name = "AcrPull"
  scope                = module.acr.id
}

############################
# BASE DE DATOS
############################
module "pg_core" {
  source              = "../../modules/database"
  name                = "notivest-${var.environment}-pg"
  db_name             = "notivest"
  admin_user          = "pgadmin"
  resource_group_name = module.rg_core.name
  location            = var.location
  environment         = var.environment
  common_tags         = local.common_tags
}

############################
# FRONTEND (Static Web)
############################
module "frontend" {
  source              = "../../modules/static-web"
  name                = "frontend-${var.environment}"
  resource_group_name = module.rg_core.name
  location            = var.location
  environment         = var.environment
  common_tags         = local.common_tags
}

############################
# MICROSERVICIOS
############################
module "apps" {
  source = "../../modules/container-app"

  for_each              = var.services

  name                  = each.key
  resource_group_name   = module.rg_core.name
  container_app_env_id  = azurerm_container_app_environment.capp_env.id
  registry_server       = module.acr.login_server
  identity_id           = azurerm_user_assigned_identity.capp_identity.id

  image   = "${module.acr.login_server}/${each.key}:${each.value.image_tag}"
  cpu     = each.value.cpu
  memory  = each.value.memory

  env_vars   = { for k, v in each.value.env : k => v if !startswith(v, "secret:") }
  secret_map = merge(
    { for k, v in each.value.env : k => substr(v, 7, length(v) - 7) if startswith(v, "secret:") },
    { "db-url" = module.pg_core.connection_string }
  )

  common_tags = local.common_tags
}
