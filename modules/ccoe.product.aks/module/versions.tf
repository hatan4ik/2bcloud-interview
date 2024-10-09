terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">=3.71.0"
      configuration_aliases = []
    }
  }
  required_version = ">= 1.3.0"
}
