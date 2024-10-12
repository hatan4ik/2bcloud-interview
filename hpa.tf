# Kubernetes resource to configure HPA (CPU/Memory autoscaling)
resource "kubernetes_horizontal_pod_autoscaler" "nginx_hpa" {
  metadata {
    name      = "nginx-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "nginx-deployment"
    }

    min_replicas = 1
    max_replicas = 10

    metrics {
      type = "Resource"

      resource {
        name                     = "cpu"
        target_average_utilization = 50
      }
    }

    metrics {
      type = "Resource"

      resource {
        name                     = "memory"
        target_average_utilization = 75
      }
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}
