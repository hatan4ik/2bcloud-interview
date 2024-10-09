locals {
  environment = "Development"
  location    = "East US"
}

resource "random_string" "workload_name" {
  length  = 9
  special = false
  upper   = false
  numeric = false
}

module "names" {
  source          = "../ccoe.product.naming//module?ref=0.10.0"
  environment     = local.environment
  location        = local.location
  workload_name   = random_string.workload_name.result
  sequence_number = 21
}

resource "azurerm_resource_group" "group" {
  name     = module.names.resource_group
  location = local.location

  tags = {
    "scope"         = "application",
    "tier"          = "keyvault",
    "env"           = local.environment,
    "workload"      = random_string.workload_name.result,
    "owner"         = "georgiana ilici",
    "owneremail"    = "georgiana.ilici@ses.com",
    "customeremail" = "-",
    "costcenter"    = "2650088"
    # The lifecycle tag is not needed to deploy the product, it is only here as part
    # of automated testing system used by the product team.
    # Please remove this tag if using code from the sample.
    "lifecycle" = "pipeline"
  }

  lifecycle {
    ignore_changes = [ # Ignored tags which are been set by policy.
      tags["owneremail"],
      tags["costcenter"],
      tags["owner"],
    ]
  }
}
