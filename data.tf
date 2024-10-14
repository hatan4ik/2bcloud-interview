# Data source for current client configuration
data "azurerm_client_config" "current" {}

##Resource Group (assuming it already exists)
data "azurerm_resource_group" "main" {
  name = "Nathanel-Candidate"
}

# # Retrieve Jenkins credentials from Key Vault
# data "azurerm_key_vault_secret" "jenkins_credentials" {
#   for_each = toset(["admin-user", "api-token"])

#   name         = "jenkins-${each.key}"
#   key_vault_id = azurerm_key_vault.main.id
# }
