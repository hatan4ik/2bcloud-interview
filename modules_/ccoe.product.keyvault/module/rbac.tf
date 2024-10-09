module "role_assignment" {
  source = "../ccoe.product.tools.rbac//module?ref=0.2.0"

  role_mapping = [
    {
      role_definition_name = "Key Vault Administrator"
      principal_ids        = var.admin_role_object_ids
    },
    {
      role_definition_name = "Key Vault Reader"
      principal_ids        = var.reader_role_object_ids
    },
    {
      role_definition_name = "Key Vault Secrets User"
      principal_ids        = var.secrets_user_role_object_ids
    },
    {
      role_definition_name = "Key Vault Certificates Officer"
      principal_ids        = var.certificates_officer_role_object_ids
    },
    {
      role_definition_name = "Key Vault Crypto Officer"
      principal_ids        = var.crypto_officer_role_object_ids
    },
    {
      role_definition_name = "Key Vault Crypto User"
      principal_ids        = var.crypto_user_role_object_ids
    },
    {
      role_definition_name = "Key Vault Crypto Service Encryption User"
      principal_ids        = var.crypto_encryption_role_object_ids
    },
    {
      role_definition_name = "Key Vault Secrets Officer"
      principal_ids        = var.secrets_officer_role_object_ids
    },
  ]

  scope_id = azurerm_key_vault.vault.id

}
