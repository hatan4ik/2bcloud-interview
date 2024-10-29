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