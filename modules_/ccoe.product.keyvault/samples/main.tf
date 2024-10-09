module "keyvault" {
  # source              = "../ccoe.product.keyvault//module?ref=4.7.0"
  source = "../module"

  resource_group_name                  = azurerm_resource_group.group.name
  environment                          = local.environment
  workload_name                        = random_string.workload_name.result
  location                             = local.location
  enabled_for_vm_deployment            = false
  enabled_for_disk_encryption          = true
  admin_role_object_ids                = [data.azurerm_client_config.current.object_id]
  reader_role_object_ids               = [data.azurerm_client_config.current.object_id]
  certificates_officer_role_object_ids = [data.azurerm_client_config.current.object_id]

  #If you want to deploy private endpoint for Key Vault private_endpoint_subnet_id should be provided. This will be the id of the subnet that private endpoint will use.
  private_endpoint = {
    "my_kvt_pep" = {
      subnet_id          = data.azurerm_subnet.spoke.id
      private_ip_address = "10.57.50.56"
    }
  }

  optional_tags = azurerm_resource_group.group.tags
}
