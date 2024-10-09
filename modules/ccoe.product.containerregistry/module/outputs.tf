output "name" {
  value       = azurerm_container_registry.acr.name
  description = "Name of the Azure Container Registry."
}

output "id" {
  value       = azurerm_container_registry.acr.id
  description = "ID of the Azure Container Registry."
}

output "url" {
  value       = azurerm_container_registry.acr.login_server
  description = "Azure Container Registry Login Server details."
}