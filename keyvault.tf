
# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "mykeyvault-${random_string.suffix.result}"
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = ["109.186.93.97", "93.173.118.226"] #Added My IP addess
    virtual_network_subnet_ids = [
      azurerm_subnet.vm_subnet.id,
      azurerm_subnet.aks_subnet.id,
      azurerm_subnet.aks_nodes.id,
      azurerm_subnet.pe_subnet.id
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete",
    ]
    certificate_permissions = [
      "List", "Get", "Create", "Delete", "Import", "Update"
    ]
  }
}
resource "azurerm_key_vault_access_policy" "jenkins_vm" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.jenkins_identity.client_id

  secret_permissions = [
    "Get",
    "Set",
    "List",
    "Delete",
    "Restore"
  ]
}

# VM Password
resource "random_password" "vm_password" {
  length  = 16
  special = true
}

# Store VM Password in Key Vault
resource "azurerm_key_vault_secret" "vm_password" {
  name         = "jenkins-vm-password"
  value        = random_password.vm_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}