resource "random_string" "workload_name" {
  length  = 9
  special = false
  numeric = false
  upper   = false
}

resource "azurerm_resource_group" "group" {
  name     = module.names.resource_group
  location = "East US"

  tags = {
    "scope"         = "application",
    "tier"          = "storage",
    "env"           = local.environment
    "workload"      = random_string.workload_name.result,
    "owner"         = "georgiana ilici",
    "owneremail"    = "georgiana.ilici@ses.com",
    "customeremail" = "-",
    "costcenter"    = "2650088",
    "ownerresgroup" = "georgiana.ilici@ses.com",

    #This tag is used for Product Team internal workflow only.
    "lifecycle" = "pipeline"
  }
}
