#-------------------------
#   Data configuration
#-------------------------
data "azuread_group" "azadgroup_adminmvp" {
  display_name = "az_sub-oa-d-verifyprd-01_owners"
}

resource "random_string" "workload_name" {
  length  = 9
  upper   = false
  numeric = false
  special = false

}

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

data "azurerm_private_dns_zone" "aks_private_dns_zone" {
  name                = "aks-${local.workload_name}-${local.environment_identifier}.privatelink.${local.location}.azmk8s.io"
  resource_group_name = data.azurerm_resource_group.spoke.name
}

data "azurerm_client_config" "current" {}
