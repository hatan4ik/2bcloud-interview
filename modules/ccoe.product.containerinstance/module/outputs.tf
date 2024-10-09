output "name" {
  value       = azurerm_container_group.this.name
  description = "The name of the Azure Container Instance."
}

output "id" {
  value       = azurerm_container_group.this.id
  description = "The ID of the Azure Container Instance."
}

output "private_ip" {
  value       = azurerm_container_group.this.ip_address
  description = "The private IP address of the Azure Container Instance."
}
