output "security_group_ids" {
  value       = { for key, nsg in azurerm_network_security_group.nsg : key => nsg.id }
  description = "Map of NSG IDs by name"
}
