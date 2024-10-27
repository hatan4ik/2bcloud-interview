# Outputs for Helm Release Module
output "release_name" {
  value       = helm_release.helm_chart.name
  description = "The name of the Helm release."
}

output "namespace" {
  value       = kubernetes_namespace.helm_namespace.metadata[0].name
  description = "The namespace where the Helm release is deployed."
}
