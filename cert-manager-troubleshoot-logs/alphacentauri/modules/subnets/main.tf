resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [each.value.address_prefix]
  service_endpoints    = each.value.service_endpoints
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
  route_table_id       = azurerm_route_table.custom_routes.id

}

output "subnet_ids" {
  value = { for k, v in azurerm_subnet.subnets : k => v.id }
}

resource "azurerm_route_table" "custom_routes" {
  name                = "custom-routes"
  resource_group_name = var.resource_group_name
  location            = data.azurerm_resource_group.main.location

  route {
    name                   = "default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }
}
