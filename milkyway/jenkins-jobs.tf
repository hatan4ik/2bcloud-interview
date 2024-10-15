# # Add this to the provider block at the top of the file
# provider "jenkins" {
#   server_url = "http://${azurerm_public_ip.jenkins_public_ip.ip_address}:8080"
#   username   = "admin"
#   password   = azurerm_key_vault_secret.jenkins_admin_password.value
# }

# # Create Jenkins admin password and store in Key Vault
# resource "random_password" "jenkins_admin_password" {
#   length  = 16
#   special = true
# }

# resource "azurerm_key_vault_secret" "jenkins_admin_password" {
#   name         = "jenkins-admin-password"
#   value        = random_password.jenkins_admin_password.result
#   key_vault_id = azurerm_key_vault.kv.id
# }

# # Create Jenkins pipeline job
# resource "jenkins_job" "app_pipeline" {
#   name     = "app-deployment-pipeline"
#   template = file("${path.module}/jenkins-pipeline.xml")

#   parameters = {
#     git_repo_url        = "https://github.com/your-org/your-app-repo.git"
#     acr_login_server    = azurerm_container_registry.acr.login_server
#     acr_username        = azurerm_container_registry.acr.admin_username
#     acr_password        = azurerm_container_registry.acr.admin_password
#     aks_resource_group  = data.azurerm_resource_group.main.name
#     aks_cluster_name    = azurerm_kubernetes_cluster.aks.name
#     azure_client_id     = azuread_service_principal.jenkins_sp.application_id
#     azure_client_secret = azuread_service_principal_password.jenkins_sp_password.value
#     azure_tenant_id     = data.azurerm_client_config.current.tenant_id
#     azure_subscription_id = data.azurerm_client_config.current.subscription_id
#   }

#   depends_on = [azurerm_virtual_machine_extension.jenkins_setup]
# }
