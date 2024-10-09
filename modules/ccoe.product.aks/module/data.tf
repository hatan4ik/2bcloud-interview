data "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  resource_group_name = local.vnet_rg_name
}

data "azurerm_subnet" "subnet" {
  name                 = local.snet_name
  virtual_network_name = local.vnet_name
  resource_group_name  = local.vnet_rg_name
}
