resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [each.value.address_prefix]

  # Add the required service endpoints
  service_endpoints = [
    "Microsoft.ContainerRegistry",
    "Microsoft.KeyVault",
    "Microsoft.Storage",
  ]
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each                = var.subnets
  subnet_id               = azurerm_subnet.subnets[each.key].id
  network_security_group_id = var.nsg_ids[each.key]  # Associate NSG dynamically
}

resource "azurerm_route_table" "custom_routes" {
  name                = "custom-routes"
  resource_group_name = var.resource_group_name
  location            = var.location

  route {
    name           = "default-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "rt_assoc" {
  for_each      = var.subnets
  subnet_id     = azurerm_subnet.subnets[each.key].id
  route_table_id = azurerm_route_table.custom_routes.id
}