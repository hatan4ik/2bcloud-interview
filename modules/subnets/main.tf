resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [each.value.address_prefix]

  service_endpoints = length(each.value.service_endpoints) > 0 ? each.value.service_endpoints : null
}

# Associate NSG with each subnet if it exists in `nsg_ids` map
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  for_each = { for key, nsg_id in var.nsg_ids : key => nsg_id if contains(keys(azurerm_subnet.subnet), key) }

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = each.value
}

# Associate Route Table with each subnet if `route_table_id` is provided
resource "azurerm_subnet_route_table_association" "subnet_route_association" {
  for_each = var.route_table_id != null ? azurerm_subnet.subnet : {}

  subnet_id      = each.value.id
  route_table_id = var.route_table_id
}

# Default NSG rule to allow VNet-local traffic
resource "azurerm_network_security_rule" "vnet_local_allow" {
  for_each                    = var.nsg_ids
  name                        = "AllowVNetInBound-${each.key}"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  network_security_group_name = each.key
  resource_group_name         = var.resource_group_name
}
