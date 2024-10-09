# This locals refer to a key vault, storage account and recovery service vault deployed in the Lab subscription. Make sure to adapt to your environment.
locals {
  environment   = "Development"
  location      = "eastus"
  workload_name = random_string.workload_name.result
  rvt = {
    name                = "rvt-vmsmvp1-eus1-t-001"
    resource_group_name = "rsg-vmsmvp1-eus1-t-021"
  }
  rvt_for_production = local.environment == "Production" ? local.rvt : null
}

resource "random_string" "workload_name" {
  length  = 9
  upper   = false
  numeric = false
  special = false
}

module "names" {
  source          = "../ccoe.product.naming//module?ref=0.9.0"
  environment     = local.environment
  location        = local.location
  workload_name   = local.workload_name
  sequence_number = 21
}

resource "azurerm_resource_group" "this" {
  name     = module.names.resource_group
  location = local.location

  tags = {
    "scope"         = "application",
    "tier"          = "VM",
    "env"           = local.environment,
    "workload"      = random_string.workload_name.result,
    "owner"         = "georgiana ilici",
    "owneremail"    = "georgiana.ilici@ses.com",
    "customeremail" = "-",
    "costcenter"    = "2650088"
    "ownerresgroup" = "georgiana.ilici@ses.com"
    "lifecycle"     = "pipeline" # #This tag is used for Product Team internal workflow only.
  }
}

#Managed Identity that will be assigned as User Assigned managed identity to the Linux VM.
resource "azurerm_user_assigned_identity" "vm_mi" {
  name                = "${module.names.managed_identity}-1"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_user_assigned_identity" "vm_mi_2" {
  name                = "${module.names.managed_identity}-2"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
}
