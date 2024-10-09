module "storage" {
  source = "../ccoe.product.storageaccount//module?ref=3.15.0"

  resource_group_name = azurerm_resource_group.this.name
  environment         = local.environment
  workload_name       = local.workload_name
  location            = local.location
  replication_type    = "GRS"
  blobdataowner_role_object_ids = [
  data.azurerm_client_config.current.object_id]

  authorized_vnet_subnet_ids = [
    data.azurerm_subnet.ado_agents.id,
    data.azurerm_subnet.spoke.id
  ]

  data_protection = {
    enable_blob_soft_delete                = true
    deleted_blob_retention_days            = 14
    enable_blob_versioning                 = true
    point_in_time_retention_period_in_days = 7
    enable_point_in_time_restore           = true
    enable_change_feed                     = true
  }

  depends_on = [
    module.keyvault
  ]
}
