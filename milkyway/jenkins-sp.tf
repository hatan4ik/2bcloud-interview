# # Service principal for Jenkins
# resource "azuread_application" "jenkins_sp" {
#   display_name = "jenkins-service-principal"
# }


# # Create Azure AD Application
# resource "azuread_application" "jenkins_app" {
#   display_name = "Jenkins-ServicePrincipal"
# }

# # Create Service Principal
# resource "azuread_service_principal" "jenkins_sp" {
#   #application_id = azuread_application.jenkins_app.application_id
#   client_id = data.azurerm_client_config.current.client_id
# }

# # Create Service Principal password
# resource "azuread_service_principal_password" "jenkins_sp_password" {
#   service_principal_id = azuread_service_principal.jenkins_sp.id
# }

# # Grant Jenkins SP contributor access to the resource group
# resource "azurerm_role_assignment" "jenkins_rg_contributor" {
#   principal_id         = azuread_service_principal.jenkins_sp.id
#   role_definition_name = "Contributor"
#   scope                = data.azurerm_resource_group.main.id
# }

# # Grant Jenkins SP AcrPush access to ACR
# resource "azurerm_role_assignment" "jenkins_acr_push" {
#   principal_id         = azuread_service_principal.jenkins_sp.id
#   role_definition_name = "AcrPush"
#   scope                = azurerm_container_registry.acr.id
# }

# # Store Jenkins SP credentials in Key Vault
# resource "azurerm_key_vault_secret" "jenkins_sp_id" {
#   name         = "jenkins-sp-id"
#   value        = azuread_application.jenkins_app.client_id
#   key_vault_id = azurerm_key_vault.kv.id
# }

# resource "azurerm_key_vault_secret" "jenkins_sp_secret" {
#   name         = "jenkins-sp-secret"
#   value        = azuread_service_principal_password.jenkins_sp_password.value
#   key_vault_id = azurerm_key_vault.kv.id
# }
