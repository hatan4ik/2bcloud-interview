# --- 1. Local Variables and Data Sources ---
locals {
  route_table_names = {
    for subnet_name, _ in var.subnets : subnet_name => "${subnet_name}-route-table"
  }
  release_name_prefix = "a${random_string.random.result}"
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
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "local_file" "image_tag" {
  filename   = "${path.module}/image_tag.txt"
  #depends_on = [null_resource.build_and_push_image]
}

data "azurerm_user_assigned_identity" "aks_identity" {
  name                = "${azurerm_kubernetes_cluster.aks.name}-agentpool"
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
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

module "network_security_groups" {
  source              = "./modules/network_security_groups"
  nsgs                = var.nsgs
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnets             = var.subnets
}

  module "subnets" {
    source              = "./modules/subnets"
    subnets             = var.subnets
    resource_group_name = data.azurerm_resource_group.main.name
    vnet_name           = azurerm_virtual_network.vnet.name
    nsg_ids             = module.network_security_groups.security_group_ids
    location            = data.azurerm_resource_group.main.location
    route_table_ids     = { for k, rt in azurerm_route_table.route_table : k => rt.id }  # Pass the actual IDs
    #route_table_ids     =  module.subnets.route_table_ids

  }

  # Route Tables Creation (Using names dynamically)
resource "azurerm_route_table" "route_table" {
  for_each            = local.route_table_names
  name                = each.value
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
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
  depends_on          = [azurerm_key_vault.kv]
}

# --- 5. AKS Setup ---
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

  depends_on = [azurerm_container_registry.acr, module.subnets]
}

# --- 6. Role Assignments for AKS ---
resource "azurerm_role_assignment" "aks_cluster_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  scope                = azurerm_kubernetes_cluster.aks.id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

resource "azurerm_role_assignment" "aks_managed_rg_network_contributor" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/mc_${data.azurerm_resource_group.main.name}_${azurerm_kubernetes_cluster.aks.name}_${data.azurerm_resource_group.main.location}"
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = data.azurerm_resource_group.main.id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

resource "azurerm_role_assignment" "aks_ingress_public_ip_network_contributor" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = azurerm_public_ip.ingress_public_ip.id
  depends_on           = [azurerm_kubernetes_cluster.aks, azurerm_public_ip.ingress_public_ip]
}

resource "azurerm_role_assignment" "aks_vnet_network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = data.azurerm_user_assigned_identity.aks_identity.principal_id
  depends_on           = [azurerm_virtual_network.vnet, azurerm_kubernetes_cluster.aks]
}

resource "azurerm_role_assignment" "aks_node_rg_network_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_kubernetes_cluster.aks.node_resource_group}"
  role_definition_name = "Network Contributor"
  principal_id         = data.azurerm_user_assigned_identity.aks_identity.principal_id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  depends_on           = [azurerm_container_registry.acr]
}

resource "azurerm_role_assignment" "acr_sp_acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.acr_sp.object_id
  depends_on           = [azurerm_container_registry.acr, azuread_service_principal.acr_sp]
}

resource "azurerm_role_assignment" "acr_sp_reader" {
  principal_id         = azuread_service_principal.acr_sp.object_id
  role_definition_name = "Reader"
  scope                = azurerm_container_registry.acr.id
  depends_on           = [azuread_service_principal.acr_sp]
}

resource "azurerm_role_assignment" "aks_kv_secrets_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  depends_on           = [azurerm_key_vault.kv, azurerm_kubernetes_cluster.aks]
}

# --- 7. Azure AD Application for ACR Access ---
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
  depends_on   = [azurerm_key_vault.kv, azuread_service_principal.acr_sp]
}

# --- 8. Public IP for Ingress ---
resource "azurerm_public_ip" "ingress_public_ip" {
  name                = "ingress-public-ip-${random_string.random.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  depends_on          = [azurerm_kubernetes_cluster.aks]
}

# --- 9. Helm Release for NGINX Ingress Controller ---
resource "helm_release" "ingress_nginx" {
  name             = local.release_name_prefix
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.11.3"
  namespace        = "myapp"
  create_namespace = true


  # Required annotations for Azure Load Balancer health probe
  set {
    name  = "controller.service.annotations.service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }
  set {
    name  = "namespaceLabels.name"
    value = "nginx-ingress"
  }

  set {
    name  = "namespaceLabels.part-of"
    value = "ingress-nginx"
  }

  set {
    name  = "namespaceLabels.app\\.kubernetes\\.io/name"
    value = "ingress-nginx"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.ingress_public_ip.ip_address
  }
   set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name = "controller.service.annotations.service.beta.kubernetes.io/azure-load-balancer-internal"
    value = "true"
  }

  set {
    name  = "controller.service.annotations.kubernetes\\.io/ingress\\.class"
    value = "nginx"
  }
  set {
    name  = "controller.service.annotations.service.beta.kubernetes.io/azure-load-balancer-resource-group"
    value = azurerm_kubernetes_cluster.aks.node_resource_group
  }
#   set {
#   name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
#   value = azurerm_kubernetes_cluster.aks.node_resource_group
# }
set {
  name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
  value = data.azurerm_resource_group.main.name # Assuming this is Nathanel-Candidate
}



  depends_on = [azurerm_kubernetes_cluster.aks, azurerm_public_ip.ingress_public_ip,
      kubernetes_secret.acr_pull_secret
  ]
}
###################


# --- 10. Docker Image Build and Push (Using az acr build) ---
resource "null_resource" "build_and_push_image" {
  triggers = {
    dockerfile_hash  = filemd5("Dockerfile") # Assuming Dockerfile is in the same directory
    # Add other triggers if needed (e.g., source code changes)
  }
  provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash
      set -euo pipefail

      ACR_NAME="${azurerm_container_registry.acr.name}"
      IMAGE_TAG="${local.image_tag}"
      IMAGE_NAME="${azurerm_container_registry.acr.login_server}/myapp:$IMAGE_TAG"
      VAULT_NAME="${azurerm_key_vault.kv.name}" # Assuming 'kv' is your Key Vault resource

      # Fetch ACR service principal credentials from Key Vault
      fetch_credentials() {
        local sp_credentials=$(az keyvault secret show --vault-name "$VAULT_NAME" --name "acr-sp-secret" --query value -o tsv)
        CLIENT_ID=$(echo $sp_credentials | jq -r .clientId)
        CLIENT_SECRET=$(echo $sp_credentials | jq -r .clientSecret)
      }

      # Function to check if the image exists
      image_exists() {
        az acr repository show-tags --name "$ACR_NAME" --repository myapp --query "[?@=='$IMAGE_TAG']" -o tsv | grep -q "$IMAGE_TAG"
      }

      # Build and push only if the image doesn't exist
      fetch_credentials # Get credentials before ACR login
      az acr login --name "$ACR_NAME" --username "$CLIENT_ID" --password "$CLIENT_SECRET" 

      if ! image_exists; then
        echo "Image with tag $IMAGE_TAG does not exist in ACR. Building and pushing..."
        az acr build --registry $ACR_NAME --image $IMAGE_NAME .
      else
        echo "Image with tag $IMAGE_TAG already exists in ACR. Skipping build and push."
      fi
    EOT
  }
  depends_on = [ azurerm_container_registry.acr, azurerm_key_vault.kv, azuread_service_principal_password.acr_sp_password ]

}

# --- 10. Docker Image Build and Push (Using ACR Tasks) ---
# resource "azurerm_container_registry_task" "build_and_push" {
#   name                = "build_myapp_image"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   container_registry_id = azurerm_container_registry.acr.id

#   platform {
#     os = "Linux" 
#   }

#   agent_pool_name = "Default" # Or specify a custom agent pool

#   step {
#     type = "Docker"
#     name = "Build and push image"

#     context_access_token = azurerm_container_registry.acr.admin_token 

#     image_names = ["${azurerm_container_registry.acr.login_server}/myapp:${local.image_tag}"]

#     content {
#       dockerfile = "Dockerfile" # Assuming Dockerfile is in the same directory as main.tf
#     }
#   }
# }


# # --- 10. Docker Image Build and Push ---
# resource "null_resource" "build_and_push_image" {
#   triggers = {
#     dockerfile_hash  = filemd5("${path.module}/Dockerfile")
#     source_code_hash = md5(join("", [for f in fileset("${path.module}/src", "**") : filemd5("${path.module}/src/${f}")]))
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       #!/bin/bash
#       set -euo pipefail

#       VAULT_NAME="${azurerm_key_vault.kv.name}"
#       ACR_NAME="${azurerm_container_registry.acr.name}"
#       TENANT_ID="${data.azurerm_client_config.current.tenant_id}"
#       IMAGE_TAG=$(git rev-parse --short HEAD)
#       IMAGE_NAME="${azurerm_container_registry.acr.login_server}/myapp:$IMAGE_TAG"

#       fetch_credentials() {
#         local sp_credentials=$(az keyvault secret show --vault-name $VAULT_NAME --name acr-sp-secret --query value -o tsv)
#         CLIENT_ID=$(echo $sp_credentials | jq -r .clientId)
#         CLIENT_SECRET=$(echo $sp_credentials | jq -r .clientSecret)
#       }

#       login_to_azure() {
#         az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID
#       }

#       login_to_acr() {
#         az acr login --name $ACR_NAME
#       }

#       image_exists() {
#         az acr repository show-tags --name $ACR_NAME --repository myapp --query "[?@=='$IMAGE_TAG']" -o tsv | grep -q "$IMAGE_TAG"
#       }

#       build_and_push_image() {
#         if ! image_exists; then
#           echo "Image with tag $IMAGE_TAG does not exist in ACR. Building and pushing..."
#           if ! docker build -t $IMAGE_NAME .; then
#             echo "ERROR: Docker build failed!"
#             exit 1
#           fi
#           if ! docker push $IMAGE_NAME; then
#             echo "ERROR: Docker push failed!"
#             exit 1
#           fi
#         else
#           echo "Image with tag $IMAGE_TAG already exists in ACR. Skipping build and push."
#         fi
#       }

#       validate_image_pull() {
#         docker pull $IMAGE_NAME
#       }

#       cleanup_local_image() {
#         docker rmi $IMAGE_NAME || true
#       }

#       save_image_tag() {
#         echo $IMAGE_TAG > ./image_tag.txt
#       }

#       main() {
#         fetch_credentials
#         login_to_azure
#         login_to_acr
#         build_and_push_image
#         validate_image_pull
#         cleanup_local_image
#         save_image_tag
#       }

#       main
#     EOT
#   }
#   depends_on = [ azurerm_container_registry.acr,
#   azurerm_key_vault.kv, azuread_service_principal_password.acr_sp_password ]

# }

resource "kubernetes_namespace" "myapp_namespace" {
  metadata {
    name = "myapp"
  }
}
# --- 11. Kubernetes Secret for ACR Pull ---
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
    azuread_service_principal_password.acr_sp_password,
    kubernetes_namespace.myapp_namespace 
    ]
}

# --- 12. MyApp Deployment and Service ---
resource "kubernetes_deployment" "myapp" {
  metadata {
    name      = "myapp"
    namespace = var.app_namespace
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

          # Set probes for health checks on root path
          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds         = 5
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 15
            period_seconds         = 10
          }
        }
      }
    }
  }
  depends_on = [azurerm_kubernetes_cluster.aks, helm_release.ingress_nginx, null_resource.build_and_push_image]
}

resource "kubernetes_service" "myapp" {
  metadata {
    name      = "myapp-service"
    namespace = var.app_namespace
    labels    = local.common_labels
  }
  spec {
    selector = local.common_labels
    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
      name        = "http"
    }
    type = "ClusterIP"
  }
  depends_on = [helm_release.ingress_nginx, kubernetes_deployment.myapp]
}

# --- 13. Kubernetes Ingress for MyApp ---
resource "kubernetes_ingress_v1" "myapp_ingress" {
  metadata {
    name      = "myapp-ingress"
    namespace = var.app_namespace
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }
  spec {
    rule {
      host = "myapp.yourdomain.com"
      http {
        path {
          path     = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.myapp.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_service.myapp, helm_release.ingress_nginx]
}
# --- 14. Update Kubeconfig with AKS Credentials ---
resource "null_resource" "update_kubeconfig" {
  triggers = {
    aks_cluster_id = azurerm_kubernetes_cluster.aks.id
  }
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${data.azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing --admin"
  }
  depends_on = [azurerm_kubernetes_cluster.aks,
  azurerm_role_assignment.aks_cluster_admin
  ]
}

# # --- 15. Verification and Testing ---
#### Make Sure App FQDN is resolvable in hosts file or in DNS if using Domain Name Ingress.
# resource "null_resource" "verify_app" {
#   provisioner "local-exec" {
#     command = <<EOT
#       INGRESS_IP=$(kubectl get svc -n ${helm_release.ingress_nginx.metadata[0].namespace} jq6663nx-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
#       curl http://$INGRESS_IP
#     EOT
#   }
#   depends_on = [kubernetes_ingress_v1.myapp_ingress, helm_release.ingress_nginx]
# }


# --- Helm Release for Cert-Manager with Timeout and CA Injection ---

# # --- Adjusted Cert-Manager Module ---
# module "cert_manager" {
#   source          = "./modules/helm_release"
#   name            = "cert-manager-${var.resource_prefix}"
#   chart           = "cert-manager"
#   repository      = "https://charts.jetstack.io"
#   chart_version   = "v1.16.1"
#   namespace       = "cert-manager"
#   create_namespace = true
#   timeout         = 1200  # Extended timeout to handle potential CRD delays
#   atomic          = true

#   set_values = [
#     { name = "crds.enabled", value = "true" },
#     { name = "serviceAccount.create", value = "true" },
#     { name = "serviceAccount.name", value = "cert-manager" },
#     # Set a higher initial delay for webhook readiness probe
#     { name = "webhook.readinessProbe.initialDelaySeconds", value = "30" },
#   ]

#   depends_on = [
#     azurerm_kubernetes_cluster.aks,
#   ]
# }

# # --- ClusterIssuer for LetsEncrypt Staging ---
# resource "kubernetes_manifest" "letsencrypt_staging_clusterissuer" {
#   manifest = {
#     apiVersion = "cert-manager.io/v1"
#     kind       = "ClusterIssuer"
#     metadata = {
#       name = "letsencrypt-staging"
#     }
#     spec = {
#       acme = {
#         server = "https://acme-staging-v02.api.letsencrypt.org/directory"
#         email  = "email@example.com"
#         privateKeySecretRef = {
#           name = "letsencrypt-staging-key"
#         }
#         solvers = [
#           {
#             http01 = {
#               ingress = {
#                 class = "nginx"
#               }
#             }
#           }
#         ]
#       }
#     }
#   }
#   depends_on = [module.cert_manager]
# }

# # --- Certificate for Webhook CA (Resolves CA injection issue) ---
# resource "kubernetes_manifest" "cert_manager_webhook_certificate" {
#   manifest = {
#     apiVersion = "cert-manager.io/v1"
#     kind       = "Certificate"
#     metadata = {
#       name      = "cert-manager-webhook-ca"
#       namespace = "cert-manager"
#     }
#     spec = {
#       secretName = "cert-manager-webhook-ca"
#       isCA       = true
#       issuerRef = {
#         name = kubernetes_manifest.letsencrypt_staging_clusterissuer.manifest.metadata.name
#         kind = "ClusterIssuer"
#       }
#       commonName = "cert-manager-webhook-ca"
#       dnsNames   = ["cert-manager-webhook.cert-manager.svc"]
#     }
#   }
#   depends_on = [
#     module.cert_manager,
#     kubernetes_manifest.letsencrypt_staging_clusterissuer,
#   ]
# }



# module "externaldns" {
#   source      = "./modules/helm_release"
#   name        = "externaldns"
#   chart       = "external-dns"
#   repository  = "https://kubernetes-sigs.github.io/external-dns"
#   namespace   = "externaldns"
#   set_values  = [
#     { name = "provider", value = "azure" },
#     { name = "azure.resourceGroup", value = "${data.azurerm_resource_group.main.name}" },
#     { name = "domainFilters[0]", value = "yourdomain.com" },
#     { name = "serviceAccount.create", value = "true" },
#     { name = "serviceAccount.name", value = "externaldns" },
#     { name = "azure.useManagedIdentity", value = "true" }
#   ]
# }

# module "redis_sentinel" {
#   source      = "./modules/helm_release"
#   name        = "redis"
#   chart       = "redis"
#   repository  = "https://charts.bitnami.com/bitnami"
#   #chart_version     = "17.10.1"
#   namespace   = "redis"
#   set_values  = [
#     { name = "usePassword", value = "true" },
#     { name = "sentinel.enabled", value = "true" },
#     { name = "auth.password", value = "your-redis-password" },
#     { name = "replica.replicaCount", value = "3" },
#     { name = "sentinel.replicaCount", value = "3" }
#   ]
# }