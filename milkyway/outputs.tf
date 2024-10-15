# This file is now used to output Jenkins-related information
# rather than creating Jenkins jobs directly through Terraform

output "jenkins_url" {
  value = "http://${azurerm_public_ip.jenkins_public_ip.ip_address}:8080"
}

output "jenkins_admin_password" {
  value     = azurerm_key_vault_secret.jenkins_admin_password.value
  sensitive = true
}
