terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.114.0"
      # Important: This is a major breaking change for the "enable_https_traffic_only/https_traffic_only_enabled" setting.
      # If you need to use an azurerm version earlier than 3.114.0, please use the previous versions of the module.
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=1.6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">=3.0.0"
    }
  }
  required_version = ">= 1.3.0"
}
