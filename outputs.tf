# Output the public IP for easy access
output "jenkins_public_ip" {
  value       = azurerm_public_ip.jenkins_public_ip.ip_address
  description = "Public IP address of the Jenkins VM"
}

output "jenkins_vm_private_ip" {
  value = azurerm_network_interface.jenkins_nic.private_ip_address
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

