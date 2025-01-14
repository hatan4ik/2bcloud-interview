# provider "azurerm" {
#   features {}
#   subscription_id = "27c83813-916e-49fa-8d2a-d35332fc8ca4"
#   use_cli = true
# }

# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }
# Required Providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    azuread = {
      source  = "hashicorp/azuread"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    helm = {
      source  = "hashicorp/helm"
    }
    random = {
      source  = "hashicorp/random"
    }
  }

  required_version = ">= 1.0"
}

# Azure Provider Configuration
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  use_cli         = true
}

# Azure AD Provider Configuration
provider "azuread" {}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

# provider "kubernetes" {
#   host                   = azurerm_kubernetes_cluster.aks.kube_admin_config[0].host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config[0].cluster_ca_certificate)
# }

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}
# Helm Provider Configuration
# provider "helm" {
#   kubernetes {
#     host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
#     client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_certificate)
#     client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_key)
#     cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config[0].cluster_ca_certificate)
#   }
# }

# Random Provider Configuration
provider "random" {}
