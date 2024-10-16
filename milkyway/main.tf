# # main.tf

# # Data declaration for current client configuration
# data "azurerm_client_config" "current" {}

# # Data declaration for resource group
# data "azurerm_resource_group" "main" {
#   name = "Nathanel-Candidate"
#   #depends_on = [ azurerm_resource_group.rg ]
# }

# # Grant purge permissions to the current user
# resource "azurerm_key_vault_access_policy" "purge_policy" {
#   key_vault_id = azurerm_key_vault.kv.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = data.azurerm_client_config.current.object_id

#   secret_permissions = [
#     "Get",
#     "List",
#     "Set",
#     "Delete",
#     "Purge",
#   ]
# }
# # Resource group
# # resource "azurerm_resource_group" "rg" {
# #   name     = "Nathanel-Candidate"
# #   location = "West Europe"
# # }

# # Virtual Network
# resource "azurerm_virtual_network" "vnet" {
#   name                = var.vnet_name
#   address_space       = [var.vnet_address_space]
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name
# }

# # Subnets
# module "subnets" {
#   source = "./modules/subnets"

#   resource_group_name = data.azurerm_resource_group.main.name
#   vnet_name           = azurerm_virtual_network.vnet.name
#   subnets             = var.subnets
# }

# # Network Security Groups
# module "network_security_groups" {
#   source = "./modules/network_security_groups"

#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   nsgs                = var.nsgs
# }

# # Associate NSGs with subnets
# resource "azurerm_subnet_network_security_group_association" "nsg_associations" {
#   for_each                  = { for k, v in var.subnets : k => v if lookup(var.nsgs, k, null) != null }
#   subnet_id                 = module.subnets.subnet_ids[each.key]
#   network_security_group_id = module.network_security_groups.nsg_ids[each.key]
# }

# # Random string for unique naming
# resource "random_string" "random" {
#   length  = 8
#   special = false
#   upper   = false
# }


# # Key Vault Configuration
# resource "azurerm_key_vault" "kv" {
#   name                        = "my-key-vault-${random_string.random.result}"
#   location                    = data.azurerm_resource_group.main.location
#   resource_group_name         = data.azurerm_resource_group.main.name
#   enabled_for_disk_encryption = true
#   tenant_id                   = data.azurerm_client_config.current.tenant_id
#   sku_name                    = "standard"
#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = data.azurerm_client_config.current.object_id
#     key_permissions = ["Get", "List", "Create", "Delete", "Update"]
#     secret_permissions = ["Get", "List", "Set", "Delete"]
#     certificate_permissions = ["Get", "List", "Create", "Delete", "Update"]
#   }
#   depends_on = [
#     azurerm_virtual_network.vnet
#   ]
# }

# # Jenkins Virtual Machine
# resource "azurerm_linux_virtual_machine" "jenkins" {
#   name                = "jenkins-vm"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   size                = "Standard_DS2_v2"
#   admin_username      = "adminuser"
#   admin_password      = random_password.vm_password.result
#   network_interface_ids = [
#     azurerm_network_interface.jenkins_nic.id,
#   ]
#   admin_ssh_key {
#     username   = "adminuser"
#     public_key = file("~/.ssh/id_rsa.pub")
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-focal"
#     sku       = "20_04-lts"
#     version   = "latest"
#   }

#   custom_data = base64encode(file("jenkins-setup.sh"))
#   depends_on = [
#     azurerm_key_vault.kv
#   ]
# }

# # Store Jenkins VM Credentials in Key Vault
# resource "azurerm_key_vault_secret" "jenkins_vm_password" {
#   name         = "jenkins-vm-password"
#   value        = random_password.vm_password.result
#   key_vault_id = azurerm_key_vault.kv.id
# }

# # Azure Container Registry
# resource "azurerm_container_registry" "acr" {
#   name                = "myacrregistry${random_string.random.result}"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   sku                 = "Premium"
#   admin_enabled       = true
#   depends_on = [
#     azurerm_linux_virtual_machine.jenkins
#   ]
# }

# # Store ACR Credentials in Key Vault
# resource "azurerm_key_vault_secret" "acr_admin_username" {
#   name         = "acr-admin-username"
#   value        = azurerm_container_registry.acr.admin_username
#   key_vault_id = azurerm_key_vault.kv.id
#   depends_on = [
#     azurerm_container_registry.acr
#   ]
# }

# resource "azurerm_key_vault_secret" "acr_admin_password" {
#   name         = "acr-admin-password"
#   value        = azurerm_container_registry.acr.admin_password
#   key_vault_id = azurerm_key_vault.kv.id
#   depends_on = [
#     azurerm_container_registry.acr
#   ]
# }

# # AKS Cluster Definition
# resource "azurerm_kubernetes_cluster" "aks" {
#   name                = "my-aks-cluster"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name
#   kubernetes_version  = "1.30.4"
#   dns_prefix          = "myakscluster"
#   default_node_pool {
#     name           = "default"
#     node_count     = 1
#     vm_size        = "Standard_DS2_v2"
#     vnet_subnet_id = module.subnets.subnet_ids["aks"]
#   }
#   identity {
#     type = "SystemAssigned"
#   }
#   depends_on = [
#     azurerm_container_registry.acr
#   ]
# }

# # Grant AKS Pull Access to ACR
# resource "azurerm_role_assignment" "aks_acr_pull" {
#   principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
#   role_definition_name = "AcrPull"
#   scope                = azurerm_container_registry.acr.id
#   depends_on = [
#     azurerm_kubernetes_cluster.aks
#   ]
# }

# # Public IP for Jenkins VM
# resource "azurerm_public_ip" "jenkins_public_ip" {
#   name                = "jenkins-public-ip"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   allocation_method   = "Static"
#   depends_on = [
#     azurerm_virtual_network.vnet
#   ]
# }

# # Network interface for Jenkins VM
# resource "azurerm_network_interface" "jenkins_nic" {
#   name                = "jenkins-nic"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = module.subnets.subnet_ids["jenkins"]
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.jenkins_public_ip.id
#   }
#   depends_on = [
#     azurerm_public_ip.jenkins_public_ip
#   ]
# }

# # Generate random password for VM
# resource "random_password" "vm_password" {
#   length  = 16
#   special = true
# }

# # Outputs
# output "jenkins_public_ip" {
#   value = azurerm_public_ip.jenkins_public_ip.ip_address
# }

# output "aks_cluster_name" {
#   value = azurerm_kubernetes_cluster.aks.name
# }

# output "acr_login_server" {
#   value = azurerm_container_registry.acr.login_server
# }

# output "key_vault_name" {
#   value = azurerm_key_vault.kv.name
# }