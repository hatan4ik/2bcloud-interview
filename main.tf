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

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.jenkins_identity.id]
  }

  # Embedded Jenkins installation and credential storage script
  custom_data = base64encode(<<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io git jq curl

    # Install Java (required for Jenkins)
    apt-get install -y openjdk-11-jdk

    # Install Jenkins
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
    sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    apt-get update
    apt-get install -y jenkins

    # Start and enable Jenkins
    systemctl enable jenkins
    systemctl start jenkins

    # Wait for Jenkins to start up
    sleep 60

    # Retrieve Jenkins admin password
    JENKINS_ADMIN_PASS=$(cat /var/lib/jenkins/secrets/initialAdminPassword)

    # Generate Jenkins API Token
    curl -X POST -u "admin:$JENKINS_ADMIN_PASS" -d 'json={"authenticityToken":"","username":"admin","password":"'"$JENKINS_ADMIN_PASS"'","credentialDescription":"Terraform-generated token"}' \
    http://localhost:8080/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken | jq -r .data.token > /tmp/jenkins-api-token.txt
    JENKINS_API_TOKEN=$(cat /tmp/jenkins-api-token.txt)

    # Store Jenkins credentials in Key Vault using Azure CLI
    az login --identity
    az keyvault secret set --vault-name "mykeyvault" --name "jenkins-admin-user" --value "admin"
    az keyvault secret set --vault-name "mykeyvault" --name "jenkins-api-token" --value "$JENKINS_API_TOKEN"

    # Clean up token file
    rm /tmp/jenkins-api-token.txt

    # Print Jenkins Initial Admin Password
    echo "Jenkins installation completed. Admin password and API token stored in Key Vault."
  EOT
  )

  depends_on = [azurerm_key_vault.main,
  azurerm_user_assigned_identity.jenkins_identity,
  azurerm_network_interface_security_group_association.jenkins_nsg_assoc]
}

# AKS Cluster (Updated - Removed docker_bridge_cidr)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "myAKSCluster"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  dns_prefix          = "myakscluster"
  kubernetes_version  = "1.30.4"
  sku_tier            = "Standard"
  # Enable addons individually
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
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

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "aks-identity"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_role_assignment" "aks_identity_role" {
  principal_id        = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope               = azurerm_key_vault.main.id
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


resource "null_resource" "download_cert_manager_crds" {
  provisioner "local-exec" {
    command = "curl -L -o ${path.module}/cert-manager.crds.yaml https://github.com/jetstack/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml"
  }
}

resource "null_resource" "download_cert_manager" {
  provisioner "local-exec" {
    command = "curl -L -o ${path.module}/cert-manager.yaml https://github.com/jetstack/cert-manager/releases/download/v1.11.0/cert-manager.yaml"
  }
}


resource "kubectl_manifest" "cert_manager_crds" {
  yaml_body = data.local_file.cert_manager_crds.content
}

resource "kubectl_manifest" "cert_manager" {
  yaml_body = data.local_file.cert_manager.content
  depends_on = [kubectl_manifest.cert_manager_crds]
}

# Redis Sentinel Helm Deployment using Bitnami chart
resource "helm_release" "redis_sentinel" {
  name       = "redis-sentinel"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "17.11.3"  # Update to a known working version
  namespace  = "default"

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
resource "kubernetes_horizontal_pod_autoscaler_v2" "nginx_hpa" {
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
          type                = "Utilization"
          average_utilization = 50
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 75
        }
      }
    }
  }
}

#Added Ingress with Static IP
resource "azurerm_public_ip" "ingress_ip" {
  name                = "nginx-ingress-ip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP for Jenkins VM (if not already present)
resource "azurerm_public_ip" "jenkins_public_ip" {
  name                = "jenkins-public-ip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# resource "helm_release" "nginx_ingress" {
#   name       = "nginx-ingress"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   version    = "4.7.1"
#   namespace  = "default"

#   set {
#     name  = "controller.service.loadBalancerIP"
#     value = azurerm_public_ip.ingress_ip.ip_address
#   }
#   set {
#     name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
#     value = "my-aks-ingress"  # Replace with your desired DNS label
#   }

#   depends_on = [
#     azurerm_kubernetes_cluster.aks,
#     azurerm_public_ip.ingress_ip
#     ]
# }




# # Helm release for External DNS
# resource "helm_release" "external_dns" {
#   version    = "6.10.0"  # Update to the latest stable version
#   name       = "external-dns"
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "external-dns"
#   namespace  = "external-dns"
#   create_namespace = true

#   set {
#     name  = "provider"
#     value = "azure"
#   }

#   set {
#     name  = "azure.resourceGroup"
#     value = data.azurerm_resource_group.main.name
#   }

#   set {
#     name  = "azure.tenantId"
#     value = data.azurerm_client_config.current.tenant_id
#   }

#   set {
#     name  = "azure.subscriptionId"
#     value = data.azurerm_client_config.current.subscription_id
#   }

#   # Use Workload Identity for authentication
#   set {
#     name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
#     value = azurerm_user_assigned_identity.external_dns.client_id
#   }
# }

# User Assigned Identity for External DNS
resource "azurerm_user_assigned_identity" "external_dns" {
  name                = "external-dns-identity"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

# Role assignment for External DNS
resource "azurerm_role_assignment" "external_dns_contributor" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
}

## Service Principal in your Terraform script and assign it the necessary role to access the Key Vault.


resource "azurerm_user_assigned_identity" "jenkins_identity" {
  name                = "jenkins-identity"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}
