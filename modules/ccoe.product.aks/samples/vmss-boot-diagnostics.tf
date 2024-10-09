/**
 * This block can be used to enable boot diagnostic settings for AKS internal VMSS. By default is "Disabled".
 * In order to enable the boot diagnostics, `{\"Enabled\" : \"False\"` should be changed to `{\"Enabled\" : \"True\"`.
 */

data "azurerm_resources" "aks-cluster-vmss" {
  resource_group_name = "MC_${azurerm_resource_group.this.name}_${module.aks.name}_${local.location}"
  type                = "Microsoft.Compute/virtualMachineScaleSets"
}

resource "null_resource" "enable_boot_diagnostics" {
  provisioner "local-exec" {
    command = <<-EOT
      az login --service-principal --username=$ARM_CLIENT_ID --password=$ARM_CLIENT_SECRET --tenant=$ARM_TENANT_ID
      az account set -s $ARM_SUBSCRIPTION_ID
      az vmss update --name ${data.azurerm_resources.aks-cluster-vmss.resources[0].name} --resource-group "MC_${azurerm_resource_group.this.name}_${module.aks.name}_${local.location}" --set virtualMachineProfile.diagnosticsProfile="{\"bootDiagnostics\": {\"Enabled\" : \"False\",\"StorageUri\":\"${local.boot_diagnostic_storage_uri}/\"}}"
    EOT
  }

  depends_on = [module.aks]
}
