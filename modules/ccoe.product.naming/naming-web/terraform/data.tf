data "azurerm_client_config" "current" {}

data "azurerm_subnet" "this" {
  name                 = local.private_endpoint_subnets[var.environment].name
  resource_group_name  = local.private_endpoint_subnets[var.environment].resource_group_name
  virtual_network_name = local.private_endpoint_subnets[var.environment].vnet_name
}

data "azurerm_subnet" "ado_agents" {
  provider = azurerm.ado_agents

  name                 = local.authorized_subnets[var.environment].name
  resource_group_name  = local.authorized_subnets[var.environment].resource_group_name
  virtual_network_name = local.authorized_subnets[var.environment].vnet_name
}