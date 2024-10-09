terraform {
  required_providers {
    random  = { version = "=3.4.0" }
    azurerm = { version = "=3.67.0" }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  skip_provider_registration = true
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy    = false
      purge_soft_deleted_secrets_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  alias                      = "corpmgmt"
  subscription_id            = "9edfcf94-ddb7-4d37-a1c8-2461e649c328"
  features {}
}
