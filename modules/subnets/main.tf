resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [each.value.address_prefix]
  service_endpoints    = try(each.value.service_endpoints, [])
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  for_each = { for subnet_name, nsg_id in var.nsg_ids : subnet_name => nsg_id if lookup(var.nsg_ids, subnet_name, null) != null }

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = var.nsg_ids[each.key]
}

resource "azurerm_subnet_route_table_association" "subnet_route_association" {
  for_each = { for subnet_name, route_table_id in var.route_table_ids : subnet_name => route_table_id if lookup(var.route_table_ids, subnet_name, null) != null }

  subnet_id      = azurerm_subnet.subnet[each.key].id
  route_table_id = var.route_table_ids[each.key]  # Use passed IDs directly
}