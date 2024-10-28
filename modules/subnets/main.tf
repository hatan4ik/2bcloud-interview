# Subnet resource with optional service endpoints
resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [each.value.address_prefix]
  service_endpoints    = each.value.service_endpoints
}

# NSG association with subnets if specified in `nsg_ids` map
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  for_each = { for subnet_name, nsg_id in var.nsg_ids : subnet_name => nsg_id if contains(keys(azurerm_subnet.subnet), subnet_name) }

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = each.value
}

# Route Table association with subnets if `route_table_id` is provided
resource "azurerm_subnet_route_table_association" "subnet_route_association" {
  for_each = var.route_table_id != null ? azurerm_subnet.subnet : {}

  subnet_id      = each.value.id
  route_table_id = var.route_table_id
}
