terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=1.4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.7.0"
    }
  }
}
