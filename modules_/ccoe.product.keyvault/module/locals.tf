locals {
  pricing_tier         = lookup({ Production = "premium", Global = "premium" }, var.environment, "standard")
  network_acls_bypass  = var.enabled_for_vm_deployment || var.enabled_for_template_deployment || var.enabled_for_disk_encryption || var.enabled_for_agw_deployment || var.enabled_for_sql_deployment ? "AzureServices" : "None"
  add_private_endpoint = var.private_endpoint != null

  default_tags = { CCoEProdVersion = "KVTv4.7.0" }
  tags         = merge(var.optional_tags, local.default_tags)
}
