data "azurerm_resource_group" "spoke" {
  name = "rsg-verifyprd-eus1-d-002"
}

data "azurerm_virtual_network" "spoke" {
  name                = "vnt-verifyprd-eus1-d-001"
  resource_group_name = data.azurerm_resource_group.spoke.name
}

data "azurerm_subnet" "spoke" {
  name                 = "snt-verifyprd-eus1-d-001"
  resource_group_name  = data.azurerm_resource_group.spoke.name
  virtual_network_name = data.azurerm_virtual_network.spoke.name
}

data "azurerm_subnet" "ado_agents" {
  provider = azurerm.corpmgmt

  name                 = "snt-agentsall-eus1-p-001-lan"
  resource_group_name  = "rsg-agentsall-eus1-p-004"
  virtual_network_name = "vnt-agentsall-eus1-p-002"
}

data "azurerm_subnet" "aci" {
  name                 = "snt-verifyprd-eus1-d-002"
  resource_group_name  = data.azurerm_resource_group.spoke.name
  virtual_network_name = data.azurerm_virtual_network.spoke.name
}

data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "sp_vault" {
  name                = "kvt-shared-eus1-d-001"
  resource_group_name = "rsg-shared-eus1-d-021"
}

