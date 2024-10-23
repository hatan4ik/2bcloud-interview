# Install NGINX Ingress Controller
resource "helm_release" "ingress_nginx" {
  name             =  random_string.random.result
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.7.1"
  namespace        = "myapp"
  create_namespace = true

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.ingress_public_ip.ip_address
  }
  set {
     name  = "controller.service.annotations.kubernetes\\.io/ingress\\.class" # Use correct annotation
     value = "nginx"
   }
    set {
     name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
     value = data.azurerm_resource_group.main.name
   }

  # depends_on = [azurerm_kubernetes_cluster.aks,
  # azurerm_public_ip.ingress_public_ip
  #]
}