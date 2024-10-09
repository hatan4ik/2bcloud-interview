terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.114.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.4.0"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
  storage_use_azuread = true

  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "corpmgmt"
  subscription_id = "9edfcf94-ddb7-4d37-a1c8-2461e649c328"
  features {}
}
