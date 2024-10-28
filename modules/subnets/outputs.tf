output "subnet_ids" {
  value = { for name, subnet in azurerm_subnet.subnet : name => subnet.id }
  description = "A map of subnet names to their respective IDs."
}


// Debug modules/subnets/outputs.tf
output "nsg_association_debug" {
  value = azurerm_subnet_network_security_group_association.subnet_nsg_association
}

output "route_table_association_debug" {
  value = azurerm_subnet_route_table_association.subnet_route_association
}

// modules/subnets/outputs.tf// modules/subnets/outputs.tf
output "nsg_associations" {
  value = {
    for subnet_name, assoc in azurerm_subnet_network_security_group_association.subnet_nsg_association : subnet_name => assoc.network_security_group_id
  }
  description = "Map of NSG associations for each subnet"
}

output "route_table_associations" {
  value = {
    for subnet_name, assoc in azurerm_subnet_route_table_association.subnet_route_association : subnet_name => assoc.route_table_id
  }
  description = "Map of Route Table associations for each subnet"
}

