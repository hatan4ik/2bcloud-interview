# main.tf

# Data declaration for current client configuration
data "azurerm_client_config" "current" {}

# Data declaration for resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Random string for unique naming
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}


# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${random_string.random.result}"
  address_space       = [var.vnet_address_space]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# Subnets
module "subnets" {
  source = "./modules/subnets"

  resource_group_name = data.azurerm_resource_group.main.name
  vnet_name           = azurerm_virtual_network.vnet.name
  subnets             = var.subnets
}

# Key Vault Configuration
resource "azurerm_key_vault" "kv" {
  name                        = "kv-${random_string.random.result}"
  location                    = data.azurerm_resource_group.main.location
  resource_group_name         = data.azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled     = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = ["Get", "List", "Create", "Delete", "Update", "Purge",]
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
    certificate_permissions = ["Get", "List", "Create", "Delete", "Update", "Purge"]
  }
   depends_on = [
     azurerm_virtual_network.vnet
   ]
}

# Store a secret in Key Vault
resource "azurerm_key_vault_secret" "app_secret" {
  name         = "app-secret"
  value        = "VeryStrongPasswordNow?"
  key_vault_id = azurerm_key_vault.kv.id
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acr${random_string.random.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false

}



# Create an Azure AD Application
resource "azuread_application" "acr_app" {
  display_name = "acr-application-${random_string.random.result}" 
}

# Create a Service Principal (linked to the application)
resource "azuread_service_principal" "acr_sp" {
  client_id               = azuread_application.acr_app.client_id
  app_role_assignment_required = false
}
# Create Service Principal password
resource "azuread_service_principal_password" "acr_sp_password" {
  service_principal_id = azuread_service_principal.acr_sp.id
}

# Store Service Principal credentials in Key Vault
resource "azurerm_key_vault_secret" "acr_sp_secret" {
  name         = "acr-sp-secret"
  value        = jsonencode({
    clientId = azuread_service_principal.acr_sp.client_id,
    clientSecret = azuread_service_principal_password.acr_sp_password.value # Get the password value
  })
  key_vault_id = azurerm_key_vault.kv.id
}

## This approach can be useful to ensure that your local kubectl configuration is updated 
#as part of Terraform workflow, especially if you're creating or updating an AKS cluster.
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${data.azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Build and push the image to ACR
resource "null_resource" "build_and_push_image" {
  provisioner "local-exec" {
    command = <<EOT
      # Retrieve Service Principal credentials from Key Vault
      SP_CREDENTIALS=$(az keyvault secret show --vault-name ${azurerm_key_vault.kv.name} --name acr-sp-secret --query value -o tsv)
      CLIENT_ID=$(echo $SP_CREDENTIALS | jq -r .clientId)
      CLIENT_SECRET=$(echo $SP_CREDENTIALS | jq -r .clientSecret)

      # Log in to Azure
      az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant ${data.azurerm_client_config.current.tenant_id}
      # Log in to ACR using Service Principal
      az acr login --name ${azurerm_container_registry.acr.name}
      ## AKS cluster config
      kubectl config get-contexts
      kubectl config use-context ${azurerm_kubernetes_cluster.aks.name}
      # Navigate to the directory containing the Dockerfile and package.json
      cd ${path.module}/alphacentauri
      docker build -t ${azurerm_container_registry.acr.login_server}/myapp:latest .
      docker push ${azurerm_container_registry.acr.login_server}/myapp:latest
    EOT
  }

  depends_on = [
    azurerm_container_registry.acr,
    azurerm_key_vault_secret.acr_sp_secret,
    azurerm_kubernetes_cluster.aks,
    null_resource.update_kubeconfig
  ]
}

# Verification: Get Nginx Ingress Controller public IP and application output
resource "null_resource" "verify_app" {
  provisioner "local-exec" {
    command = <<EOT
      export INGRESS_IP=$(kubectl get svc -n ingress-nginx -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
      echo "Nginx Ingress Controller Public IP: $INGRESS_IP"
      curl http://$INGRESS_IP
EOT
  }

  depends_on = [
    helm_release.myapp,
    helm_release.nginx_ingress
  ]
}

# AKS Cluster Definition
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${random_string.random.result}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  kubernetes_version  = "1.30.4"
  sku_tier            = "Standard"
  dns_prefix          = "aks-${random_string.random.result}"
  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = module.subnets.subnet_ids["aks"]
  }
  identity {
    type = "SystemAssigned"
  }
  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = "172.244.0.0/16"
    dns_service_ip     = "172.244.0.10"
  }

  depends_on = [
    azurerm_container_registry.acr
  ]
}

# Grant AKS Managed Identity access to Key Vault secrets
resource "azurerm_role_assignment" "aks_kv_secrets_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "Network Contributor"
  scope                = data.azurerm_resource_group.main.id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

# Grant AKS Pull Access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

# User Assigned Identity for Pod
resource "azurerm_user_assigned_identity" "aks_pod_identity" {
  name                = "aks-pod-identity-${random_string.random.result}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# Grant the User Assigned Identity access to the Key Vault secret
resource "azurerm_role_assignment" "kv_secret_reader" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks_pod_identity.principal_id
}

# Install NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.ingress_public_ip.ip_address
  }
  set {
    name  = "controller.service.annotations.kubernetes\\.io/ingress\\.class" # Use correct annotation
    value = "nginx"
  }
  #  set {
  #   name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
  #   value = data.azurerm_resource_group.main.name
  # }

  depends_on = [azurerm_kubernetes_cluster.aks,
  azurerm_public_ip.ingress_public_ip,
  azurerm_role_assignment.aks_network_contributor
  ]
}

# Public IP for Nginx Ingress Controller
resource "azurerm_public_ip" "ingress_public_ip" {
  name                = "ingress-public-ip-${random_string.random.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
}

# Install cert-manager
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Install Redis Bitnami Sentinel
resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = "redis"
  create_namespace = true

  # Configure Redis Sentinel as needed
  # ...
}

# Deploy application using Helm
resource "helm_release" "myapp" {
  name       = "myapp"
  chart      = "./helm-chart"
  namespace  = "default"
  create_namespace = true
  max_history = 5
  timeout    = 600

  set {
    name  = "image.repository"
    value = azurerm_container_registry.acr.login_server
  }

  set {
    name  = "image.tag"
    value = "latest"
  }

  set {
    name  = "image.pullPolicy"
    value = "Always"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.className"
    value = "nginx"
  }

  set {
    name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "nginx"
  }

  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-prod"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = "myapp.${azurerm_public_ip.ingress_public_ip.ip_address}.nip.io"
  }

  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/"
  }

  set {
    name  = "ingress.hosts[0].paths[0].pathType"
    value = "Prefix"
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "myapp-tls"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = "myapp.${azurerm_public_ip.ingress_public_ip.ip_address}.nip.io"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
    value = azurerm_user_assigned_identity.aks_pod_identity.client_id
  }

  set {
    name  = "keyVault.enabled"
    value = "true"
  }

  set {
    name  = "keyVault.name"
    value = azurerm_key_vault.kv.name
  }

  set {
    name  = "keyVault.secretName"
    value = azurerm_key_vault_secret.app_secret.name
  }

  set {
    name  = "keyVault.tenantId"
    value = data.azurerm_client_config.current.tenant_id
  }

  set {
    name  = "podIdentity.enabled"
    value = "true"
  }

  set {
    name  = "podIdentity.userAssignedIdentityName"
    value = azurerm_user_assigned_identity.aks_pod_identity.name
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_container_registry.acr,
    azurerm_key_vault_secret.app_secret,
    helm_release.cert_manager,
    helm_release.nginx_ingress,
    azurerm_user_assigned_identity.aks_pod_identity
  ]
}

# Outputs
output "jenkins_public_ip" {
  value = azurerm_public_ip.ingress_public_ip.ip_address
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  value = module.subnets.subnet_ids
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "container_registry_id" {
  value = azurerm_container_registry.acr.id
}

output "user_assigned_identity_id" {
  value = azurerm_user_assigned_identity.aks_pod_identity.id
}

output "nginx_ingress_ip" {
  value = azurerm_public_ip.ingress_public_ip.ip_address
}