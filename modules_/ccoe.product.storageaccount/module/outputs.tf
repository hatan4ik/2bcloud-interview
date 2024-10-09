output "id" {
  value       = azurerm_storage_account.resource.id
  description = "The ID of the created Azure storage account resource."
}

output "name" {
  value       = azurerm_storage_account.resource.name
  description = "The name of the created Azure storage account resource."
}

output "primary_access_key" {
  value       = azurerm_storage_account.resource.primary_access_key
  description = "The primary_access_key of the created Azure storage account resource."
  sensitive   = true
}

output "primary_blob_endpoint" {
  value       = azurerm_storage_account.resource.primary_blob_endpoint
  description = "The primary_blob_endpoint of the created Azure storage account resource."
}

output "ATP_id" {
  value       = azurerm_advanced_threat_protection.this[*].id
  description = "The Advanced Threat Protection id."
}

output "private_endpoint_id" {
  description = "The private endpoint Id of Storage account"
  value       = values(azurerm_private_endpoint.private_endpoint).*.id
}

output "private_endpoint_name" {
  description = "The private endpoint name of Storage account"
  value       = values(module.private_endpoint_names).*.private_endpoint
}
