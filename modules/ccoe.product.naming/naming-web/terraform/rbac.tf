resource "azurerm_role_assignment" "product_team_sp_blob_data_contributor" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
}
