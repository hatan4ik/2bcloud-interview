# Data source for current client configuration
data "azurerm_client_config" "current" {}

##Resource Group (assuming it already exists)
data "azurerm_resource_group" "main" {
  name = "Nathanel-Candidate"
}


data "local_file" "cert_manager_crds" {
  filename = "${path.module}/cert-manager.crds.yaml"
  depends_on = [null_resource.download_cert_manager_crds]
}

data "local_file" "cert_manager" {
  filename = "${path.module}/cert-manager.yaml"
  depends_on = [null_resource.download_cert_manager]
}

data "azurerm_public_ip" "jenkins_public_ip" {
  name = "jenkins_nic_public"
  resource_group_name = azurerm_network_interface.jenkins_nic_public.resource_group_name
}

# # Retrieve Jenkins credentials from Key Vault
# data "azurerm_key_vault_secret" "jenkins_credentials" {
#   for_each = toset(["admin-user", "api-token"])

#   name         = "jenkins-${each.key}"
#   key_vault_id = azurerm_key_vault.main.id
# }
