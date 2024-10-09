terraform {
  required_providers {
    azurerm = { version = ">=3.0.1" }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "ado_agents"
  subscription_id = local.authorized_subnets[var.environment].subscription_id
  features {}
}

variable "environment" {
  type        = string
  description = "Environment where the resources are deployed."
}

locals {
  location      = "westeurope"
  workload_name = "naming"
}

module "naming" {
  source        = "../ccoe.product.naming//module?ref=0.3.0"
  environment   = var.environment
  location      = local.location
  workload_name = local.workload_name
}

module "rg_naming" {
  source          = "../ccoe.product.naming//module?ref=0.3.0"
  environment     = var.environment
  location        = local.location
  workload_name   = local.workload_name
  sequence_number = 21
}

module "private_endpoint_naming" {
  source                         = "../ccoe.product.naming//module?ref=0.3.0"
  environment                    = var.environment
  location                       = local.location
  workload_name                  = local.workload_name
  private_endpoint_subnet_name   = local.private_endpoint_subnets[var.environment].name
  private_endpoint_resource_name = azurerm_storage_account.this.name

  depends_on = [azurerm_storage_account.this]
}