# main.tf

# Data declaration for current client configuration
data "azurerm_client_config" "current" {}

# Data declaration for resource group
data "azurerm_resource_group" "main" {
  name = "Nathanel-Candidate"
}

# Resource group
# resource "azurerm_resource_group" "rg" {
#   name     = "my-resource-group"
#   location = "East US"
# }

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# Subnet for Jenkins VM
resource "azurerm_subnet" "jenkins_subnet" {
  name                 = "jenkins-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Subnet for ACR
resource "azurerm_subnet" "acr_subnet" {
  name                 = "acr-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
  service_endpoints    = ["Microsoft.ContainerRegistry"]
}

# NSG for Jenkins VM
resource "azurerm_network_security_group" "jenkins_nsg" {
  name                = "jenkins-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG for AKS
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "jenkins_nsg_association" {
  subnet_id                 = azurerm_subnet.jenkins_subnet.id
  network_security_group_id = azurerm_network_security_group.jenkins_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "aks_nsg_association" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# Route table for AKS
resource "azurerm_route_table" "aks_route_table" {
  name                = "aks-route-table"
  location            = azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.main.name

  route {
    name                   = "internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }
}

# Associate route table with AKS subnet
resource "azurerm_subnet_route_table_association" "aks_route_table_association" {
  subnet_id      = azurerm_subnet.aks_subnet.id
  route_table_id = azurerm_route_table.aks_route_table.id
}

# Random string for unique naming
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "my-key-vault-${random_string.random.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete",
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = ["0.0.0.0/0"]  # Be cautious with this setting in production
  }
}

# Generate random password for VM
resource "random_password" "vm_password" {
  length  = 16
  special = true
}

# VM Admin password in Key Vault
resource "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  value        = random_password.vm_password.result
  key_vault_id = azurerm_key_vault.kv.id
}

# Network interface for Jenkins VM
resource "azurerm_network_interface" "jenkins_nic" {
  name                = "jenkins-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jenkins_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins_public_ip.id
  }
}

# Public IP for Jenkins VM
resource "azurerm_public_ip" "jenkins_public_ip" {
  name                = "jenkins-public-ip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

# Virtual Machine for Jenkins
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "jenkins-vm"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = azurerm_key_vault_secret.vm_password.value
  network_interface_ids = [
    azurerm_network_interface.jenkins_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(file("jenkins_setup.sh"))
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "my-aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.main.name
  dns_prefix          = "myakscluster"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  addon_profile {
    oms_agent {
      enabled = false
    }
    azure_policy {
      enabled = true
    }
  }

  sku_tier = "Standard"  # Required for ACR integration

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "myacrregistry${random_string.random.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = true

  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action   = "Allow"
      ip_range = "0.0.0.0/0"  # Be cautious with this setting in production
    }
    virtual_network {
      action    = "Allow"
      subnet_id = azurerm_subnet.acr_subnet.id
    }
  }
}

# Grant AKS pull access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Service principal for Jenkins
resource "azuread_application" "jenkins_sp" {
  display_name = "jenkins-service-principal"
}

resource "azuread_service_principal" "jenkins_sp" {
  application_id = azuread_application.jenkins_sp.application_id
}

resource "azuread_service_principal_password" "jenkins_sp_password" {
  service_principal_id = azuread_service_principal.jenkins_sp.id
}

# Grant Jenkins SP contributor access to the resource group
resource "azurerm_role_assignment" "jenkins_rg_contributor" {
  principal_id         = azuread_service_principal.jenkins_sp.id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.rg.id
}

# Grant Jenkins SP AcrPush access to ACR
resource "azurerm_role_assignment" "jenkins_acr_push" {
  principal_id         = azuread_service_principal.jenkins_sp.id
  role_definition_name = "AcrPush"
  scope                = azurerm_container_registry.acr.id
}

# Store Jenkins SP credentials in Key Vault
resource "azurerm_key_vault_secret" "jenkins_sp_id" {
  name         = "jenkins-sp-id"
  value        = azuread_service_principal.jenkins_sp.application_id
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "jenkins_sp_secret" {
  name         = "jenkins-sp-secret"
  value        = azuread_service_principal_password.jenkins_sp_password.value
  key_vault_id = azurerm_key_vault.kv.id
}

# Create Jenkins admin password and store in Key Vault
resource "random_password" "jenkins_admin_password" {
  length  = 16
  special = true
}

resource "azurerm_key_vault_secret" "jenkins_admin_password" {
  name         = "jenkins-admin-password"
  value        = random_password.jenkins_admin_password.result
  key_vault_id = azurerm_key_vault.kv.id
}

# Update Jenkins VM setup script
resource "azurerm_virtual_machine_extension" "jenkins_setup" {
  name                 = "jenkins-setup"
  virtual_machine_id   = azurerm_linux_virtual_machine.jenkins.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/hatan4ik/2bcloud-interview/main/jenkins-setup.sh"],
        "commandToExecute": "bash jenkins-setup.sh ${azurerm_container_registry.acr.login_server} ${azuread_service_principal.jenkins_sp.application_id} ${azuread_service_principal_password.jenkins_sp_password.value} ${azurerm_kubernetes_cluster.aks.name} ${data.azurerm_resource_group.main.name}"
    }
SETTINGS
  depends_on = [
    azurerm_linux_virtual_machine.jenkins,
    azurerm_container_registry.acr,
    azuread_service_principal.jenkins_sp,
    azurerm_kubernetes_cluster.aks
  ]

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

# Create a static public IP for NGINX Ingress
resource "azurerm_public_ip" "ingress_public_ip" {
  name                = "ingress-public-ip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
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

  depends_on = [azurerm_kubernetes_cluster.aks, azurerm_public_ip.ingress_public_ip]
}

# Example secret for the application
resource "azurerm_key_vault_secret" "app_secret" {
  name         = "app-secret"
  value        = "mysecretvalue"
  key_vault_id = azurerm_key_vault.kv.id
}

# Install Secrets Store CSI Driver
resource "helm_release" "csi_secrets_store_driver" {
  name             = "csi-secrets-store"
  repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart            = "secrets-store-csi-driver"
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Install Azure Key Vault Provider for Secrets Store CSI Driver
resource "helm_release" "csi_secrets_store_provider_azure" {
  name             = "csi-secrets-store-provider-azure"
  repository       = "https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts"
  chart            = "csi-secrets-store-provider-azure"
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "secrets-store-csi-driver.syncSecret.enabled"
    value = "true"
  }

  set {
    name  = "secrets-store-csi-driver.enableSecretRotation"
    value = "true"
  }

  depends_on = [azurerm_kubernetes_cluster.aks, helm_release.csi_secrets_store_driver]
}

# Create a user-assigned managed identity for pod identity
resource "azurerm_user_assigned_identity" "aks_pod_identity" {
  resource_group_name = data.azurerm_resource_group.main.name
  location            = azurerm_resource_group.rg.location
  name                = "aks-pod-identity"
}

# Assign the pod identity the Reader role on the Key Vault
resource "azurerm_role_assignment" "pod_identity_kv_reader" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.aks_pod_identity.principal_id
}

# Assign the pod identity the Key Vault Secrets User role
resource "azurerm_role_assignment" "pod_identity_kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks_pod_identity.principal_id
}

# Assign AKS the Managed Identity Operator role for the pod identity
resource "azurerm_role_assignment" "aks_identity_operator" {
  scope                = azurerm_user_assigned_identity.aks_pod_identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
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
    value = "${azurerm_container_registry.acr.login_server}/myapp"
  }

  set {
    name  = "image.tag"
    value = "latest"  # Consider using a specific version in production
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
    value = "myapp.example.com"
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
    value = "myapp.example.com"
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
    helm_release.csi_secrets_store_provider_azure,
    azurerm_role_assignment.aks_identity_operator,
    azurerm_user_assigned_identity.aks_pod_identity
  ]
}

# Output values
output "jenkins_public_ip" {
  value = azurerm_public_ip.jenkins_public_ip.ip_address
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

output "ingress_public_ip" {
  value = azurerm_public_ip.ingress_public_ip.ip_address
}

output "app_url" {
  value = "https://myapp.example.com"
}

