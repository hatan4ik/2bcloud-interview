provider "azurerm" {
  features {}
  subscription_id = "27c83813-916e-49fa-8d2a-d35332fc8ca4"
  use_cli = true
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}