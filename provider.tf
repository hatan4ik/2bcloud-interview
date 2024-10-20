provider "azurerm" {
  features {}
  subscription_id = "27c83813-916e-49fa-8d2a-d35332fc8ca4"
  use_cli = true
}


provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate      = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key              = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate  = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate      = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key              = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate  = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
  }
}

# provider "kubernetes" {
#   config_path = "~/.kube/config"
#}