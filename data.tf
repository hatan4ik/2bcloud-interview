# # Retrieve Jenkins credentials from Key Vault
# data "azurerm_key_vault_secret" "jenkins_credentials" {
#   for_each = toset(["admin-user", "api-token"])

#   name         = "jenkins-${each.key}"
#   key_vault_id = azurerm_key_vault.main.id
# }
