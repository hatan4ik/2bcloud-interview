locals {
  environment = "Development"
  location    = "East US"
}

resource "random_string" "workload_name" {
  length  = 9
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = module.names.resource_group
  location = local.location

  tags = {
    "scope"         = "application",
    "tier"          = "acr",
    "env"           = local.environment,
    "workload"      = random_string.workload_name.result,
    "owner"         = "CCoE-Product-Team",
    "owneremail"    = "ccoe_product_team@ses.com",
    "customeremail" = "-",
    "costcenter"    = "-",
    "lifecycle"     = "pipeline"
  }
}

resource "azurerm_user_assigned_identity" "uid" {
  name                = "${module.names.container_registry}-uid"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
}

module "names" {
  source          = "../ccoe.product.naming//module?ref=0.9.0"
  environment     = local.environment
  location        = local.location
  workload_name   = random_string.workload_name.result
  sequence_number = 21
}


