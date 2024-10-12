# Deploy Cert Manager using Helm
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.7.1"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "extraArgs"
    value = "--enable-certificate-owner-ref"
  }

  # External DNS integration (you need to configure DNS provider credentials)
  set {
    name  = "external-dns"
    value = "true"
  }

  # Workload identity settings (if required)
  set {
    name  = "workloadIdentity"
    value = "true"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}