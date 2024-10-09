# Grant `Storage Account Backup Contributor` permissions to the Backup vault on storage accounts.
resource "azurerm_role_assignment" "this" {
  count = var.backup_vault != null ? 1 : 0

  scope                = azurerm_storage_account.resource.id
  role_definition_name = "Storage Account Backup Contributor"
  principal_id         = var.backup_vault.system_assigned_id
}

# Create a backup policy.
resource "azurerm_data_protection_backup_policy_blob_storage" "this" {
  count = var.backup_vault != null ? 1 : 0

  name               = "${azurerm_storage_account.resource.name}-backup-policy"
  vault_id           = var.backup_vault.id
  retention_duration = "P30D" # Default 30 day backup.
}

# Configure backup.
resource "azurerm_data_protection_backup_instance_blob_storage" "this" {
  count = var.backup_vault != null ? 1 : 0

  name               = "${azurerm_storage_account.resource.name}-backup-instance"
  vault_id           = var.backup_vault.id
  location           = var.location
  storage_account_id = azurerm_storage_account.resource.id
  backup_policy_id   = azurerm_data_protection_backup_policy_blob_storage.this[0].id

  depends_on = [azurerm_role_assignment.this]
}
