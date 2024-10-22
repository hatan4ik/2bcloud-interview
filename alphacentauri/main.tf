# --- 1. Local Variables and Data Sources ---
locals {
  dockerfile_hash  = filemd5("${path.module}/Dockerfile")
  source_code_hash = md5(join("", [for f in fileset("${path.module}/src", "**") : filemd5("${path.module}/src/${f}")]))
  image_tag        = trimspace(data.local_file.image_tag.content)
  resource_prefix  = var.resource_prefix
  common_labels = {
    "app.kubernetes.io/name"     = "myapp"
    "app.kubernetes.io/instance" = var.resource_prefix
  }
  ingress_labels = {
    "app.kubernetes.io/name"    = "ingress-nginx"
    "app.kubernetes.io/part-of" = "ingress-nginx"
  }
  ingress_controller_args = [
    "/nginx-ingress-controller",
    "--publish-service=$(POD_NAMESPACE)/nginx-ingress-controller",
    "--election-id=ingress-controller-leader",
    "--controller-class=k8s.io/ingress-nginx",
    "--configmap=$(POD_NAMESPACE)/${local.resource_prefix}-ingress-nginx-controller",
    "--health-check-path=/healthz",
    "--health-check-port=10254",
    "--tcp-services-configmap=$(POD_NAMESPACE)/tcp-services",
    "--udp-services-configmap=$(POD_NAMESPACE)/udp-services"
  ]
  ingress_controller_ports = {
    "http"  = 80
    "https" = 443
  }
}

data "azurerm_client_config" "current" {}
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
data "kubernetes_all_namespaces" "all" {
  depends_on = [null_resource.update_kubeconfig]
}

data "local_file" "image_tag" {
  filename   = "${path.module}/image_tag.txt"
  depends_on = [null_resource.build_and_push_image]
}

# --- 2. Random String and Network Resources ---
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${random_string.random.result}"
  address_space       = [var.vnet_address_space]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

module "subnets" {
  source              = "./modules/subnets"
  resource_group_name = data.azurerm_resource_group.main.name
  vnet_name           = azurerm_virtual_network.vnet.name
  subnets             = var.subnets
}

# --- 3. Azure Key Vault ---
resource "azurerm_key_vault" "kv" {
  name                        = "kv-${random_string.random.result}"
  location                    = data.azurerm_resource_group.main.location
  resource_group_name         = data.azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  enabled_for_disk_encryption = true

  access_policy {
    tenant_id               = data.azurerm_client_config.current.tenant_id
    object_id               = data.azurerm_client_config.current.object_id
    key_permissions         = ["Get", "List", "Create", "Delete", "Update", "Purge"]
    secret_permissions      = ["Get", "List", "Set", "Delete", "Purge"]
    certificate_permissions = ["Get", "List", "Create", "Delete", "Update", "Purge"]
  }
}

# --- 4. Azure Container Registry (ACR) ---
resource "azurerm_container_registry" "acr" {
  name                = "acr${random_string.random.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Premium"
  admin_enabled       = false
}

# --- 5. Kubernetes Setup (AKS Cluster) ---
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${random_string.random.result}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  kubernetes_version  = var.kubernetes_version
  dns_prefix          = "aks-${random_string.random.result}"
  sku_tier            = "Standard"

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.vm_size
    vnet_subnet_id = module.subnets.subnet_ids["aks"]
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = "172.244.0.0/16"
    dns_service_ip    = "172.244.0.10"
    load_balancer_sku = "standard"
  }

  depends_on = [azurerm_container_registry.acr]
}

# --- 6. Role Assignments for AKS ---
resource "azurerm_role_assignment" "aks_managed_rg_network_contributor" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/mc_${data.azurerm_resource_group.main.name}_${azurerm_kubernetes_cluster.aks.name}_${data.azurerm_resource_group.main.location}"
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "Network Contributor"
  scope                = data.azurerm_resource_group.main.id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Kubernetes secret for ACR pull
resource "kubernetes_secret" "acr_pull_secret" {
  count = length(var.target_namespaces) > 0 ? length(var.target_namespaces) : 1

  metadata {
    name      = "acr-pull-secret"
    namespace = length(var.target_namespaces) > 0 ? var.target_namespaces[count.index] : "default"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${azurerm_container_registry.acr.login_server}" = {
          auth = base64encode("${azuread_service_principal.acr_sp.client_id}:${azuread_service_principal_password.acr_sp_password.value}")
        }
      }
    })
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azuread_service_principal_password.acr_sp_password
  ]
}

resource "azurerm_role_assignment" "aks_kv_secrets_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# --- 7. Update Kubeconfig with AKS Credentials ---
resource "null_resource" "update_kubeconfig" {
  triggers = {
    aks_cluster_id = azurerm_kubernetes_cluster.aks.id
  }
  provisioner "local-exec" {
    command = <<EOT
    az aks get-credentials --resource-group ${data.azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing --admin
    kubectl config get-contexts
    kubectl config use-context ${azurerm_kubernetes_cluster.aks.name}
  EOT
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

# --- 8. Azure AD Application for ACR Access ---
resource "azuread_application" "acr_app" {
  display_name = "acr-application-${random_string.random.result}"
}

resource "azuread_service_principal" "acr_sp" {
  client_id                    = azuread_application.acr_app.client_id
  app_role_assignment_required = false
}

resource "azuread_service_principal_password" "acr_sp_password" {
  service_principal_id = azuread_service_principal.acr_sp.id
}

resource "azurerm_key_vault_secret" "acr_sp_secret" {
  name  = "acr-sp-secret"
  value = jsonencode({
    clientId     = azuread_service_principal.acr_sp.client_id
    clientSecret = azuread_service_principal_password.acr_sp_password.value
  })
  key_vault_id = azurerm_key_vault.kv.id
}

# --- 9. Public IP for Ingress ---
resource "azurerm_public_ip" "ingress_public_ip" {
  name                = "ingress-public-ip-${random_string.random.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# --- 10. Kubernetes Namespace for Ingress NGINX ---
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

# --- 11. Define Service Account for NGINX Ingress ---
resource "kubernetes_service_account" "nginx_ingress_sa" {
  metadata {
    name      = "${local.resource_prefix}-nginx-ingress-serviceaccount"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
  depends_on = [kubernetes_namespace.ingress_nginx]
}

# Define Role for NGINX Ingress
resource "kubernetes_role" "nginx_ingress_role" {
  metadata {
    name      = "${local.resource_prefix}-nginx-ingress-role"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
}

# Define Role Binding for NGINX Ingress
resource "kubernetes_role_binding" "nginx_ingress_role_binding" {
  metadata {
    name      = "${local.resource_prefix}-nginx-ingress-role-binding"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.nginx_ingress_sa.metadata[0].name
    namespace = kubernetes_service_account.nginx_ingress_sa.metadata[0].namespace
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role.nginx_ingress_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# --- 12. Define ClusterRole and ClusterRole Binding for NGINX Ingress ---
resource "kubernetes_cluster_role" "nginx_ingress_cluster_role" {
  metadata {
    name = "${local.resource_prefix}-nginx-ingress-cluster-role"
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "secrets", "configmaps"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses", "ingressclasses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }
}

resource "kubernetes_cluster_role_binding" "nginx_ingress_cluster_role_binding" {
  metadata {
    name = "${local.resource_prefix}-nginx-ingress-cluster-role-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.nginx_ingress_sa.metadata[0].name
    namespace = kubernetes_service_account.nginx_ingress_sa.metadata[0].namespace
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.nginx_ingress_cluster_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# Define ConfigMap for NGINX Ingress Controller
resource "kubernetes_config_map" "nginx_ingress_config" {
  metadata {
    name      = "${local.resource_prefix}-nginx-ingress-config"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels    = merge(local.ingress_labels, local.common_labels)
  }

  data = {
    "proxy-body-size"               = "4m"
    "enable-underscores-in-headers" = "true"
    # Add more configuration options as needed
  }
}

# --- 13. Kubernetes NGINX Ingress Deployment ---
resource "kubernetes_deployment" "nginx_ingress" {
  metadata {
    name      = "${var.resource_prefix}-nginx-ingress"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels    = merge(local.ingress_labels, local.common_labels)
  }

  spec {
    replicas = var.ingress_replicas

    selector  {
      match_labels = {
        "app.kubernetes.io/name"     = "ingress-nginx"
        "app.kubernetes.io/instance" = var.resource_prefix
        "app.kubernetes.io/part-of"  = "ingress-nginx"
      }
    }

    template {
      metadata {
        labels      = {
          "app.kubernetes.io/name"     = "ingress-nginx"
          "app.kubernetes.io/instance" = var.resource_prefix
          "app.kubernetes.io/part-of"  = "ingress-nginx"
        }
        annotations = {
          "prometheus.io/port"   = "10254"
          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.nginx_ingress_sa.metadata[0].name

        container {
          name  = "nginx-ingress-controller"
          image = var.nginx_ingress_image
          args  = local.ingress_controller_args

          security_context {
            allow_privilege_escalation = true
            run_as_user                = 101
            capabilities {
              drop = ["ALL"]
              add  = ["NET_BIND_SERVICE"]
            }
          }

          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = 10254
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path   = "/healthz"
              port   = 10254
              scheme = "HTTP"
            }
            period_seconds = 10
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.ingress_nginx, kubernetes_config_map.nginx_ingress_config]
}

# --- 14. NGINX Ingress Service ---
resource "kubernetes_service" "nginx_ingress_controller" {
  metadata {
    name      = "nginx-ingress-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels    = merge(local.ingress_labels, local.common_labels)
    annotations = {
      "service.beta.kubernetes.io/azure-load-balancer-resource-group" = data.azurerm_resource_group.main.name
    }
  }

  spec {
    type = "LoadBalancer"

    selector = {
      "app.kubernetes.io/name"     = "ingress-nginx"
      "app.kubernetes.io/instance" = var.resource_prefix
      "app.kubernetes.io/part-of"  = "ingress-nginx"
      }
    
    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    port  {
      name        = "https"
      port        = 443
      target_port = 443
      protocol    = "TCP"
    }

    load_balancer_ip = azurerm_public_ip.ingress_public_ip.ip_address
  }
  depends_on = [kubernetes_deployment.nginx_ingress]

}

# --- 15. MyApp Deployment and Service ---
resource "kubernetes_deployment" "myapp" {
  metadata {
    name      = "myapp"
    namespace = "default"
    labels    = local.common_labels
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = local.common_labels
    }

    template {
      metadata {
        labels = local.common_labels
      }

      spec {
        image_pull_secrets {
          name = length(var.target_namespaces) > 0 ? kubernetes_secret.acr_pull_secret[0].metadata[0].name : "acr-pull-secret"
        }

        container {
          name  = "myapp"
          image = "${azurerm_container_registry.acr.login_server}/myapp:${local.image_tag}"
          port {
            container_port = 3000
            protocol       = "TCP"
          }
        }
      }
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks, kubernetes_service.myapp, null_resource.build_and_push_image]
}

resource "kubernetes_service" "myapp" {
  metadata {
    name      = "myapp-service"
    namespace = "default"
    labels    = local.common_labels
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
      name        = "http"
    }

    selector = {
      app = "myapp"
    }
  }
}

# --- 16. Ingress Configuration for MyApp ---
resource "kubernetes_ingress" "myapp_ingress" {
  metadata {
    name      = "${var.resource_prefix}-nginx-ingress"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
    labels = merge(local.ingress_labels, local.common_labels)
  }

  spec {
    rule {
      host = "myapp.yourdomain.com"
      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.myapp.metadata[0].name
            service_port = 80
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.nginx_ingress_controller, kubernetes_service.myapp]
}

# --- 17. Build and Push Docker Image to ACR ---
resource "null_resource" "build_and_push_image" {
  triggers = {
    dockerfile_hash  = filemd5("${path.module}/Dockerfile")
    source_code_hash = md5(join("", [for f in fileset("${path.module}/src", "**") : filemd5("${path.module}/src/${f}")]))
  }
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -euo pipefail

      VAULT_NAME="${azurerm_key_vault.kv.name}"
      ACR_NAME="${azurerm_container_registry.acr.name}"
      TENANT_ID="${data.azurerm_client_config.current.tenant_id}"
      IMAGE_TAG=$(git rev-parse --short HEAD)
      IMAGE_NAME="${azurerm_container_registry.acr.login_server}/myapp:$IMAGE_TAG"

      main() {
        fetch_credentials
        login_to_azure
        login_to_acr
        build_and_push_image
        validate_image_pull
        cleanup_local_image
        save_image_tag
      }

      fetch_credentials() {
        local sp_credentials=$(az keyvault secret show --vault-name $VAULT_NAME --name acr-sp-secret --query value -o tsv)
        CLIENT_ID=$(echo $sp_credentials | jq -r .clientId)
        CLIENT_SECRET=$(echo $sp_credentials | jq -r .clientSecret)
      }

      login_to_azure() {
        az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID
        az account show --query id -o tsv
      }

      login_to_acr() {
        az acr login --name $ACR_NAME
      }

      build_and_push_image() {
        docker build -t $IMAGE_NAME .
        docker push $IMAGE_NAME
      }

      validate_image_pull() {
        docker pull $IMAGE_NAME
      }

      cleanup_local_image() {
        docker rmi $IMAGE_NAME
      }

      save_image_tag() {
        echo $IMAGE_TAG > ./image_tag.txt
      }

      main
    EOT
  }

  depends_on = [
    azurerm_container_registry.acr,
    azurerm_key_vault_secret.acr_sp_secret,
    azurerm_kubernetes_cluster.aks
  ]
}

# --- 18. Verification and Testing ---
resource "null_resource" "verify_app" {
  provisioner "local-exec" {
    command = <<EOT
      export INGRESS_IP=$(kubectl get svc -n ingress-nginx nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
      echo "Nginx Ingress Controller Public IP: $INGRESS_IP"
      curl http://$INGRESS_IP
    EOT
  }

  depends_on = [kubernetes_deployment.nginx_ingress, kubernetes_ingress.myapp_ingress, kubernetes_service.myapp]
}
