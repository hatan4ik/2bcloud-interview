terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "=1.6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.30.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.4.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = false
    }
  }
}

provider "azurerm" {
  alias           = "corpmgmt"
  subscription_id = "9edfcf94-ddb7-4d37-a1c8-2461e649c328"
  features {}
}

locals {
  environment = "Development"
  location    = "East US"
}

resource "random_string" "workload_name" {
  length  = 9
  special = false
  numeric = false
  upper   = false
}

module "names" {
  source = "../ccoe.product.naming//module?ref=0.11.0"

  environment     = local.environment
  location        = local.location
  workload_name   = random_string.workload_name.result
  suffix          = "aci"
  sequence_number = 21
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = module.names.resource_group

  tags = {
    "scope"         = "application",
    "tier"          = "aci",
    "env"           = local.environment,
    "workload"      = random_string.workload_name.result,
    "owner"         = "CCoE-Product-Team",
    "owneremail"    = "ccoe_product_team@ses.com",
    "customeremail" = "-",
    "costcenter"    = "-",
    "lifecycle"     = "pipeline" #This tag is used for Product Team internal workflow only. Please remove if copying.
  }
}

