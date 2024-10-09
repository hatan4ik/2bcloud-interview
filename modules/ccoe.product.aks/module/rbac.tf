module "role_assignment" {
  source = "../ccoe.product.tools.rbac//module?ref=0.2.0"

  role_mapping = [
    {
      role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
      principal_ids        = var.cluster_admin_role_object_ids
    },
    {
      role_definition_name = "Azure Kubernetes Service Cluster User Role"
      principal_ids        = var.cluster_user_role_object_ids
    },
    {
      role_definition_name = "Azure Kubernetes Service Contributor Role"
      principal_ids        = var.contributor_role_object_ids
    },
    {
      role_definition_name = "Azure Kubernetes Service RBAC Admin"
      principal_ids        = var.rbac_admin_role_object_ids
    },
    {
      role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
      principal_ids        = var.rbac_cluster_admin_role_object_ids
    },
    {
      role_definition_name = "Azure Kubernetes Service RBAC Reader"
      principal_ids        = var.rbac_reader_role_object_ids
    },
    {
      role_definition_name = "Azure Kubernetes Service RBAC Writer"
      principal_ids        = var.rbac_writer_role_object_ids
    },
  ]

  scope_id = azurerm_kubernetes_cluster.aks.id
}