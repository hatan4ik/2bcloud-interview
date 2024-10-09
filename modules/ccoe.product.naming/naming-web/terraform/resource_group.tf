resource "azurerm_resource_group" "this" {
  location = local.location
  name     = module.rg_naming.resource_group

  tags = {
    "scope"         = "application",
    "tier"          = "documentation",
    "env"           = lower(var.environment),
    "workload"      = local.workload_name
    "owner"         = "platform",
    "owneremail"    = "ccoe_platform_team@ses.com",
    "customeremail" = "-",
    "costcenter"    = "2650088",
  }
}
