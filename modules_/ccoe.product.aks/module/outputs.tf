output "name" {
  description = "The Kubernetes Managed Cluster name."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "id" {
  description = "The Kubernetes Managed Cluster ID."
  value       = azurerm_kubernetes_cluster.aks.id
}

output "fqdn" {
  description = "The FQDN of the Azure Kubernetes Managed Cluster."
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "private_fqdn" {
  description = "The FQDN for the Kubernetes Cluster when private link has been enabled, which is only resolvable inside the Virtual Network used by the Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.aks.private_fqdn
}

output "kube_admin_config" {
  description = "A kube_admin_config block. This is only available when Role Based Access Control with Azure Active Directory is enabled."
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config
}

output "kube_admin_config_raw" {
  description = "Raw Kubernetes config for the admin account to be used by kubectl and other compatible tools. This is only available when Role Based Access Control with Azure Active Directory is enabled."
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
}

output "kube_config" {
  description = "A kube_config block."
  value       = azurerm_kubernetes_cluster.aks.kube_config
}

output "kube_config_raw" {
  description = "Raw Kubernetes config to be used by kubectl and other compatible tools."
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "node_resource_group" {
  description = "Resource Group which contains the resources for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "kubelet_identity" {
  description = "A kubelet_identity block"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity
}

output "identity" {
  description = "A managed identity block for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.aks.identity
}

output "client_key" {
  description = "Client Keys for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive   = true
}

output "client_certificate" {
  description = "Client Certificate for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
}

output "cluster_ca_certificate" {
  description = "Client CA Certificate for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
}

output "host" {
  description = "Host details for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
}

output "username" {
  description = "Usernames for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].username
}

output "password" {
  description = "Passwords for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].password
  sensitive   = true
}

output "key_vault_secrets_provider" {
  description = "Keyvault secrets driver configuration for this cluster."
  value       = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider
}

output "oidc_issuer_enabled" {
  description = "Whether or not the OIDC feature is enabled or disabled."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_enabled
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL that is associated with the cluster."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "node_resource_group_id" {
  description = "The ID of the Resource Group containing the resources for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.aks.node_resource_group_id
}