terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "<storage-account-name>"
    container_name       = "tfstate"
    key                  = "notivest-prod.tfstate"
  }
}
