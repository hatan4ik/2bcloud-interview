module "keyvault" {
  source = "../ccoe.product.keyvault//module?ref=4.5.0"

  resource_group_name         = azurerm_resource_group.this.name
  environment                 = local.environment
  workload_name               = random_string.workload_name.result
  location                    = local.location
  enabled_for_vm_deployment   = true
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
  admin_role_object_ids       = [data.azurerm_client_config.current.object_id]
  authorized_vnet_subnet_ids  = [data.azurerm_subnet.ado_agents.id]

  optional_tags = azurerm_resource_group.this.tags
}

module "credentials" {
  source = "../ccoe.product.tools.credentials//module?ref=0.10.0"

  # By using this module, the username and password are randomly generated and stored in the key vault with the format
  # ${resource_group}-${workload_name}-admin-username and ${resource_group}-${workload_name}-admin-password
  # The user or service principal deploying the VM must have the role "Key Vault Administrator"
  # or similar on the key vault provided in this input.
  # The key vault must have the setting `enabled_for_disk_encryption = true`. This also requires
  # `soft_delete_enabled = true` and `purge_protection_enabled = true`.
  # The key vault must be deployed in the same region as the VM.
  workload_name       = local.workload_name
  resource_group_name = azurerm_resource_group.this.name
  keyvault_id         = module.keyvault.id
  environment         = local.environment
  location            = local.location
  resource_type       = "VirtualMachine"

  depends_on = [module.keyvault]
}

resource "tls_private_key" "sample_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
