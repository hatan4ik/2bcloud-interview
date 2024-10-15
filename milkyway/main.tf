# main.tf

# Data declaration for current client configuration
data "azurerm_client_config" "current" {}

# Data declaration for resource group
data "azurerm_resource_group" "main" {
  name = "Nathanel-Candidate"
  #depends_on = [ azurerm_resource_group.rg ]
}

# Resource group
# resource "azurerm_resource_group" "rg" {
#   name     = "Nathanel-Candidate"
#   location = "West Europe"
# }

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.main.location
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
  location            = data.azurerm_resource_group.main.location
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
  location            = data.azurerm_resource_group.main.location
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
  location            = data.azurerm_resource_group.main.location
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
  location                    = data.azurerm_resource_group.main.location
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
  location            = data.azurerm_resource_group.main.location
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
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
}

# Virtual Machine for Jenkins
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "jenkins-vm"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  size                = "Standard_DS2_v2"
  admin_username      = "adminuser"
  admin_password      = azurerm_key_vault_secret.vm_password.value
  network_interface_ids = [
    azurerm_network_interface.jenkins_nic.id,
  ]
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "19_04-gen2"
    version   = "latest"
  }

  custom_data = base64encode(file("jenkins-setup.sh"))
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "my-aks-cluster"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  kubernetes_version  = "1.30.4"
  sku_tier            = "Standard"
  dns_prefix          = "myakscluster"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
    temporary_name_for_rotation = "tempnodepool"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    service_cidr       = "172.16.0.0/16"  # Non-overlapping CIDR
    dns_service_ip     = "172.16.0.10"    # Must be within service_cidr range
  }

  # addon_profile {
  #   oms_agent {
  #     enabled = false
  #   }
  #   azure_policy {
  #     enabled = true
  #   }
  #}

# Required for ACR integration

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "myacrregistry${random_string.random.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Premium"
  admin_enabled       = true

  network_rule_set {
    default_action = "Allow"
  }
}

# Grant AKS pull access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
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
        "fileUris": ["https://raw.githubusercontent.com/hatan4ik/2bcloud-interview/refs/heads/main/milkyway/jenkins-setup.sh"],
        "commandToExecute": "bash jenkins-setup.sh"
    }
SETTINGS
  depends_on = [
    azurerm_linux_virtual_machine.jenkins,
    azurerm_container_registry.acr,
    #azuread_service_principal.jenkins_sp,
    azurerm_kubernetes_cluster.aks
  ]

}



# Create a static public IP for NGINX Ingress
resource "azurerm_public_ip" "ingress_public_ip" {
  name                = "ingress-public-ip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}



# Example secret for the application
resource "azurerm_key_vault_secret" "app_secret" {
  name         = "app-secret"
  value        = "mysecretvalue"
  key_vault_id = azurerm_key_vault.kv.id
}


# Create a user-assigned managed identity for pod identity
resource "azurerm_user_assigned_identity" "aks_pod_identity" {
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
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

