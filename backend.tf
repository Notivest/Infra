terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate1032"
    container_name       = "tfstate"
    key                  = "notivest-dev.tfstate"
  }
}
