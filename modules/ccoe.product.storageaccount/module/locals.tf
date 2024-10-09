locals {
  for_each = var.private_endpoint

  location            = lower(replace(var.location, " ", ""))
  container_names     = toset(var.container_names)
  table_names         = toset(var.table_names)
  queue_names         = toset(var.queue_names)
  allow_ragrs         = var.account_tier == "Premium" ? false : var.replication_type
  allow_hns           = var.account_tier == "Standard" ? var.is_hns_enabled : false
  change_feed_enabled = var.account_tier == "Premium" ? false : var.data_protection.enable_change_feed
  #If Storage account kind will be supported, this will have to be excluded as well when account kind BlockBlobStorage is used
  #access_tier = var.account_kind == "BlockBlobStorage" ? null : var.account_kind == "Storage" ? null : var.access_tier
  access_tier = var.account_kind == "BlockBlobStorage" ? null : var.access_tier

  default_tags = {
    CCoEProdVersion = "STAv4.1.0"
  }

  tags = merge(var.optional_tags, local.default_tags)
}
