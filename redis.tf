# Redis Sentinel Helm Deployment using Bitnami chart
resource "helm_release" "redis_sentinel" {
  name       = "redis-sentinel"
  namespace  = "default"
  chart      = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "15.5.0"

  set {
    name  = "replica.replicaCount"
    value = "3"
  }

  set {
    name  = "sentinel.enabled"
    value = "true"
  }

  set {
    name  = "sentinel.masterSet"
    value = "mymaster"
  }

  set {
    name  = "redis.replicaCount"
    value = "3"
  }

  set {
    name  = "persistence.size"
    value = "10Gi"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}
