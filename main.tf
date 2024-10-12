# Data source for current client configuration
data "azurerm_client_config" "current" {}

##Resource Group (assuming it already exists)
data "azurerm_resource_group" "main" {
  name = "Nathanel-Candidate"
}

# Define the resource group:
# **Subscription is not allowing to create a new resource groups at all.
# resource "azurerm_resource_group" "main" {
#   name     = "NathanelS-Candidate-RG"
#   location = "eastus"
# }

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}


# Virtual Network
resource "azurerm_virtual_network" "main_vnet" {
  name                = "main-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# Subnets
resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]
}

resource "azurerm_subnet_service_endpoint_storage_policy" "aks_storage_policy" {
  name                = "aks-storage-endpoint-policy"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  definition {
    name        = "AzureStorage"
    description = "Allow access to Azure Storage"
    service_resources = [
      "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${data.azurerm_resource_group.main.name}/providers/Microsoft.Storage/storageAccounts/*"
    ]
  }
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]

  delegation {
    name = "aksDelegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
  service_endpoint_policy_ids = [
    azurerm_subnet_service_endpoint_storage_policy.aks_storage_policy.id
  ]
}

resource "azurerm_subnet" "aks_nodes" {
  name                 = "aks-nodes"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.4.0/24"]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]
}

resource "azurerm_subnet" "pe_subnet" {
  name                 = "pe-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]
}

# NAT Gateway and Public IP
resource "azurerm_public_ip" "nat_gateway_ip" {
  name                = "nat-gateway-ip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "main" {
  name                    = "main-nat-gateway"
  location                = data.azurerm_resource_group.main.location
  resource_group_name     = data.azurerm_resource_group.main.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip.id
}

# Associate NAT Gateway with VM subnet
resource "azurerm_subnet_nat_gateway_association" "main" {
  subnet_id      = azurerm_subnet.vm_subnet.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# Network Security Groups (NSG)
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowInternetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "pe_nsg" {
  name                = "pe-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowPrivateEndpointInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

# Associate NSG with PE subnet
resource "azurerm_subnet_network_security_group_association" "pe_nsg_assoc" {
  subnet_id                 = azurerm_subnet.pe_subnet.id
  network_security_group_id = azurerm_network_security_group.pe_nsg.id
}

# Network Interface for Jenkins VM
resource "azurerm_network_interface" "jenkins_nic" {
  name                = "jenkins-nic"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "jenkins_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.jenkins_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "mystorageaccount${random_string.suffix.result}"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "mykeyvault-${random_string.suffix.result}"
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = ["109.186.93.97", "93.173.118.226"] #Added My IP addess
    virtual_network_subnet_ids = [
      azurerm_subnet.vm_subnet.id,
      azurerm_subnet.aks_subnet.id,
      azurerm_subnet.aks_nodes.id,
      azurerm_subnet.pe_subnet.id
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete",
    ]
  }
}

# VM Password
resource "random_password" "vm_password" {
  length  = 16
  special = true
}

# Store VM Password in Key Vault
resource "azurerm_key_vault_secret" "vm_password" {
  name         = "jenkins-vm-password"
  value        = random_password.vm_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}

# Jenkins VM with embedded installation script
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "jenkins-vm"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.jenkins_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

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

  # Embedded Jenkins installation script
  custom_data = base64encode(<<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io git
    systemctl enable docker
    systemctl start docker

    # Install Java (required for Jenkins)
    apt-get install -y openjdk-11-jdk

    # Add Jenkins repository and key
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
    sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

    # Install Jenkins
    apt-get update
    apt-get install -y jenkins

    # Start and enable Jenkins
    systemctl enable jenkins
    systemctl start jenkins

    # Print Jenkins Initial Admin Password
    echo "Jenkins installation completed. You can find the initial admin password at:"
    cat /var/lib/jenkins/secrets/initialAdminPassword
  EOT
  )

  depends_on = [azurerm_network_interface_security_group_association.jenkins_nsg_assoc]
}

# AKS Cluster (Updated - Removed docker_bridge_cidr)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "myAKSCluster"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  dns_prefix          = "myakscluster"
  kubernetes_version  = "1.30.4"
  sku_tier            = "Standard"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.aks_nodes.id
  }
  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  role_based_access_control_enabled = true
  # identity {
  #   type = "SystemAssigned"
  # }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = "172.244.0.0/16"
    dns_service_ip     = "172.244.0.10"
    # Removed docker_bridge_cidr since it's no longer supported
  }

  depends_on = [azurerm_subnet.aks_nodes]
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "myacrregistry${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false
}

# Role assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  #principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  principal_id                     = azurerm_kubernetes_cluster.aks.service_principal[0].client_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true

  depends_on = [azurerm_kubernetes_cluster.aks, azurerm_container_registry.acr]
}

# Private Endpoints
resource "azurerm_private_endpoint" "storage" {
  name                = "storage-pe"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.pe_subnet.id

  private_service_connection {
    name                           = "storage-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "keyvault-pe"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.pe_subnet.id

  private_service_connection {
    name                           = "keyvault-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Private DNS Zones Virtual Network Links (Fixed references)
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "storage-vnet-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id  # Fixed reference
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "keyvault-vnet-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.main_vnet.id  # Fixed reference
}

# DNS A Records for Private Endpoints (with correct references)
resource "azurerm_private_dns_a_record" "storage" {
  name                = "mystorageaccount"
  zone_name           = azurerm_private_dns_zone.storage.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "keyvault" {
  name                = "mykeyvault"
  zone_name           = azurerm_private_dns_zone.keyvault.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address]
}

# Output values
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
# Deploy Cert Manager using Helm
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.7.1"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "extraArgs"
    value = "--enable-certificate-owner-ref"
  }

  # External DNS integration (you need to configure DNS provider credentials)
  set {
    name  = "external-dns"
    value = "true"
  }

  # Workload identity settings (if required)
  set {
    name  = "workloadIdentity"
    value = "true"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}# Redis Sentinel Helm Deployment using Bitnami chart
resource "helm_release" "redis_sentinel" {
  name       = "redis-sentinel"
  namespace  = "default"
  chart      = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "15.7.2"

  set {
    name  = "replica.replicaCount"
    value = "3"
  }

  set {
    name  = "sentinel.enabled"
    value = "true"
  }

  set {
    name  = "sentinel.masterSet"
    value = "mymaster"
  }

  set {
    name  = "redis.replicaCount"
    value = "3"
  }

  set {
    name  = "persistence.size"
    value = "10Gi"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Kubernetes resource to configure HPA (CPU/Memory autoscaling)
resource "kubernetes_horizontal_pod_autoscaler" "nginx_hpa" {
  metadata {
    name      = "nginx-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "nginx-deployment" 
    }

    min_replicas = 1
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type = "Utilization"
          average_utilization = 50 
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type = "Utilization"
          average_utilization = 75 
        }
      }
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}
