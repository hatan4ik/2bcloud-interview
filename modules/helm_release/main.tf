# Create Kubernetes namespace if it doesn't already exist
resource "kubernetes_namespace" "helm_namespace" {
  metadata {
    name = var.namespace
  }

  lifecycle {
    prevent_destroy       = false
    create_before_destroy = true
  }
}

# Helm release with dynamic values and namespace dependency
resource "helm_release" "helm_chart" {
  name       = var.name
  repository = var.repository
  chart      = var.chart
  version    = var.chart_version
  namespace  = var.namespace

  # Dynamic set block for Helm values
  dynamic "set" {
    for_each = var.set_values
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  depends_on = [kubernetes_namespace.helm_namespace]
}
