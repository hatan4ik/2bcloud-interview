data "azurerm_container_registry" "this" {
  name                = var.registry.name
  resource_group_name = var.registry.resource_group_name
}

data "azurerm_key_vault" "this" {
  name                = var.registry.keyvault_name
  resource_group_name = var.registry.keyvault_resource_group_name
}

data "azurerm_key_vault_secret" "credentials" {
  for_each = {
    username = var.registry.username_secret_name
    password = var.registry.password_secret_name
  }

  key_vault_id = data.azurerm_key_vault.this.id
  name         = each.value
}
