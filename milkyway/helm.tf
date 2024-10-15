# # Install NGINX Ingress Controller
# resource "helm_release" "nginx_ingress" {
#   name             = "nginx-ingress"
#   repository       = "https://kubernetes.github.io/ingress-nginx"
#   chart            = "ingress-nginx"
#   namespace        = "ingress-nginx"
#   create_namespace = true

#   set {
#     name  = "controller.service.loadBalancerIP"
#     value = azurerm_public_ip.ingress_public_ip.ip_address
#   }

#   depends_on = [azurerm_kubernetes_cluster.aks, azurerm_public_ip.ingress_public_ip]
# }
# # Install cert-manager
# resource "helm_release" "cert_manager" {
#   name             = "cert-manager"
#   repository       = "https://charts.jetstack.io"
#   chart            = "cert-manager"
#   namespace        = "cert-manager"
#   create_namespace = true

#   set {
#     name  = "installCRDs"
#     value = "true"
#   }

#   depends_on = [azurerm_kubernetes_cluster.aks, azurerm_linux_virtual_machine.jenkins]
# }

# # Install Secrets Store CSI Driver
# resource "helm_release" "csi_secrets_store_driver" {
#   name             = "csi-secrets-store"
#   repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
#   chart            = "secrets-store-csi-driver"
#   namespace        = "kube-system"
#   create_namespace = false

#   set {
#     name  = "syncSecret.enabled"
#     value = "true"
#   }

#   depends_on = [azurerm_kubernetes_cluster.aks]
# }

# # Install Azure Key Vault Provider for Secrets Store CSI Driver
# resource "helm_release" "csi_secrets_store_provider_azure" {
#   name             = "csi-secrets-store-provider-azure"
#   repository       = "https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts"
#   chart            = "csi-secrets-store-provider-azure"
#   namespace        = "kube-system"
#   create_namespace = false

#   set {
#     name  = "secrets-store-csi-driver.syncSecret.enabled"
#     value = "true"
#   }

#   set {
#     name  = "secrets-store-csi-driver.enableSecretRotation"
#     value = "true"
#   }

#   depends_on = [azurerm_kubernetes_cluster.aks, helm_release.csi_secrets_store_driver]
# }

# # Deploy application using Helm
# resource "helm_release" "myapp" {
#   name       = "myapp"
#   chart      = "./helm-chart"
#   namespace  = "default"
#   create_namespace = true
#   max_history = 5
#   timeout    = 600

#   set {
#     name  = "image.repository"
#     value = "${azurerm_container_registry.acr.login_server}/myapp"
#   }

#   set {
#     name  = "image.tag"
#     value = "latest"  # Consider using a specific version in production
#   }

#   set {
#     name  = "image.pullPolicy"
#     value = "Always"
#   }

#   set {
#     name  = "ingress.enabled"
#     value = "true"
#   }

#   set {
#     name  = "ingress.className"
#     value = "nginx"
#   }

#   set {
#     name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
#     value = "nginx"
#   }

#   set {
#     name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
#     value = "letsencrypt-prod"
#   }

#   set {
#     name  = "ingress.hosts[0].host"
#     value = "myapp.example.com"
#   }

#   set {
#     name  = "ingress.hosts[0].paths[0].path"
#     value = "/"
#   }

#   set {
#     name  = "ingress.hosts[0].paths[0].pathType"
#     value = "Prefix"
#   }

#   set {
#     name  = "ingress.tls[0].secretName"
#     value = "myapp-tls"
#   }

#   set {
#     name  = "ingress.tls[0].hosts[0]"
#     value = "myapp.example.com"
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = "true"
#   }

#   set {
#     name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
#     value = azurerm_user_assigned_identity.aks_pod_identity.client_id
#   }

#   set {
#     name  = "keyVault.enabled"
#     value = "true"
#   }

#   set {
#     name  = "keyVault.name"
#     value = azurerm_key_vault.kv.name
#   }

#   set {
#     name  = "keyVault.secretName"
#     value = azurerm_key_vault_secret.app_secret.name
#   }

#   set {
#     name  = "keyVault.tenantId"
#     value = data.azurerm_client_config.current.tenant_id
#   }

#   set {
#     name  = "podIdentity.enabled"
#     value = "true"
#   }

#   set {
#     name  = "podIdentity.userAssignedIdentityName"
#     value = azurerm_user_assigned_identity.aks_pod_identity.name
#   }

#   depends_on = [
#     azurerm_kubernetes_cluster.aks,
#     azurerm_container_registry.acr,
#     azurerm_key_vault_secret.app_secret,
#     helm_release.cert_manager,
#     helm_release.nginx_ingress,
#     helm_release.csi_secrets_store_provider_azure,
#     azurerm_role_assignment.aks_identity_operator,
#     azurerm_user_assigned_identity.aks_pod_identity
#   ]
# }
