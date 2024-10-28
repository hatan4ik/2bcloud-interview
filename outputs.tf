# Outputs
output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

# output "virtual_network_id" {
#   value = azurerm_virtual_network.vnet.id
# }

# output "subnet_ids" {
#   value = module.subnets.subnet_ids
# }

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "container_registry_id" {
  value = azurerm_container_registry.acr.id
}


output "public_ip_address" {
  value = azurerm_public_ip.ingress_public_ip.ip_address
}

output "public_ip_fqdn" {
  value = azurerm_public_ip.ingress_public_ip.fqdn
}
output "aks_cluster_kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

######################
# output "nsg_associations" {
#   value = module.subnets.nsg_associations
#   description = "Map of NSG associations by subnet name"
# }

# output "route_table_associations" {
#   value = module.subnets.route_table_associations
#   description = "Map of Route Table associations by subnet name"
# }

