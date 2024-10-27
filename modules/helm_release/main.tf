# --- Main Helm Release Module ---
resource "kubernetes_namespace" "helm_namespace" {
  metadata {
    name = var.namespace
  }

  # Ensure namespace is created before the Helm release
  lifecycle {
    create_before_destroy = true
  }
}

resource "helm_release" "helm_chart" {
  name       = var.name
  repository = var.repository
  chart      = var.chart
  version    = var.version
  namespace  = kubernetes_namespace.helm_namespace.metadata[0].name

  dynamic "set" {
    for_each = var.set_values
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  depends_on = [kubernetes_namespace.helm_namespace]
}
