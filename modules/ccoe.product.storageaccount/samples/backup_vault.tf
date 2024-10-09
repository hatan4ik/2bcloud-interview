resource "azurerm_data_protection_backup_vault" "this" {
  name                = "${random_string.workload_name.result}-backup-vault"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant"
  identity {
    type = "SystemAssigned"
  }
}