resource "null_resource" "immutable_policy" {
  count = var.immutability_policy == null ? 0 : 1

  provisioner "local-exec" {
    command = <<EOF
      az storage container immutability-policy create \
      --resource-group ${var.resource_group_name} \
      --account-name ${azurerm_storage_account.resource.name} \
      --container-name ${var.immutability_policy.container_name} \
      --allow-protected-append-writes-all true \
      --period ${var.immutability_policy.period_in_days}
    EOF
  }
  depends_on = [azurerm_storage_account.resource]
}


resource "null_resource" "legal_hold_policy" {
  count = var.legal_hold_policy == null ? 0 : 1

  provisioner "local-exec" {
    command = <<EOF
      az storage container legal-hold set \
      --tags ${var.legal_hold_policy.tag} \
      --container-name ${var.legal_hold_policy.container_name} \
      --account-name ${azurerm_storage_account.resource.name} \
      --resource-group ${var.resource_group_name} \
      --allow-protected-append-writes-all true
    EOF
  }
  depends_on = [azurerm_storage_account.resource]
}
