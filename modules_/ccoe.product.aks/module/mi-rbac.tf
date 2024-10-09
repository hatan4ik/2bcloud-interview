####
#### Permissions and roles needed for the Managed Identity
####

#---------
# Permissions
#---------

resource "azurerm_role_assignment" "rbac_assign_dns" {
  scope                = var.aks_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = var.managed_identity.principal_id
}

resource "azurerm_role_assignment" "rbac_assign_udr" {
  scope                = data.azurerm_subnet.subnet.route_table_id
  role_definition_name = "Network Contributor"
  principal_id         = var.managed_identity.principal_id
}

resource "azurerm_role_assignment" "rbac_assign_vnet" {
  scope                = data.azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = var.managed_identity.principal_id
}
