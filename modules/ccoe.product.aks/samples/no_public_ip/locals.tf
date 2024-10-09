#----------------
#   Locals TF
#----------------

locals {
  environment_identifier      = lower(substr(local.environment, 0, 1))
  environment                 = "Development"
  location                    = "eastus"
  workload_name               = "verifyprd"
  boot_diagnostic_storage_uri = "https://stasharedeus1d001.blob.core.windows.net"
  location_identifier         = local.location == "westeurope" ? "weu1" : "eus1"

  tags = {
    scope              = "-"
    tier               = "-",
    location           = local.location
    env                = lower(local.environment)
    workload           = local.workload_name
    owner              = "CCoE Product team"
    owneremail         = "ccoe_product_team@ses.com"
    costcenter         = "2650088"
    ownerResGroup      = "-",
    Domain             = "-",
    customeremail      = "-",
    DescriptionbyOwner = "-",
    lifecycle          = "pipeline",
  }
}
