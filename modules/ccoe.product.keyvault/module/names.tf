module "names" {
  source          = "../ccoe.product.naming//module?ref=0.10.0"
  environment     = var.environment
  location        = var.location
  workload_name   = var.workload_name
  sequence_number = var.sequence_number
}

module "private_endpoint_names" {
  for_each = var.private_endpoint

  source                         = "../ccoe.product.naming//module?ref=0.10.0"
  environment                    = var.environment
  location                       = var.location
  workload_name                  = var.workload_name
  private_endpoint_resource_name = azurerm_key_vault.vault.name
  private_endpoint_subnet_name   = basename(var.private_endpoint[each.key].subnet_id)
}
