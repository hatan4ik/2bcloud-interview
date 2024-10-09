output "name" {
  value       = azurerm_key_vault.vault.name
  description = "The name of the created Azure Key Vault resource."
}

output "id" {
  value       = azurerm_key_vault.vault.id
  description = "The ID of the created Azure Key Vault resource."
}

output "private_endpoint_id" {
  description = "The private endpoint Id of KeyVault"
  value       = values(azurerm_private_endpoint.private_endpoint).*.id
}


output "private_endpoint_name" {
  description = "The private endpoint name of KeyVault"
  value       = values(module.private_endpoint_names).*.private_endpoint
}
