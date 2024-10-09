#---------
# Managed identity
#---------
resource "azurerm_user_assigned_identity" "aks_mi" {
  name                = module.names.managed_identity
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name

  lifecycle {
    ignore_changes = [
      tags["costcenter"],
      tags["env"],
      tags["owner"],
      tags["owneremail"],
      tags["ownerresgroup"],
      tags["scope"],
      tags["tier"],
      tags["workload"],
    ]
  }
}

# We assign the contributor role of the Kubelet identity to the resources groups used by AKS.
# While provisioning the cluster for the first time, the Kubelet identity is not used but the managed identity created above.
# However when performing an upgrade of the default pool or change the VM size, this managed identity will not be longer used.
# The role assignments below ensure that both resource groups (Kube API resource group and VMss resource group) have the permissions.
# A custom role may be created instead of using the contributor role where the permissions to manage disks, disks encryption, loadbalancer 
# and other potential Azure resources that can be created by AKS.
resource "azurerm_role_assignment" "default_pool" {
  principal_id                     = module.aks.kubelet_identity[0].object_id
  role_definition_name             = "Contributor"
  scope                            = azurerm_resource_group.this.id
  skip_service_principal_aad_check = true

}

resource "azurerm_role_assignment" "default_pool_dyn_grp" {
  principal_id                     = module.aks.kubelet_identity[0].object_id
  role_definition_name             = "Contributor"
  scope                            = module.aks.node_resource_group_id
  skip_service_principal_aad_check = true

}