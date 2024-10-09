data "azurerm_backup_policy_vm" "backup_policy" {
  count = var.recovery_service_vault == null ? 0 : 1

  name                = var.backup_policy_name
  recovery_vault_name = var.recovery_service_vault.name
  resource_group_name = var.recovery_service_vault.resource_group_name
}
