/**
 * # Azure Keyvault
 *
 * This product will deploy a keyvault following SES standards.
 *
 */

resource "azurerm_key_vault" "vault" {
  name                            = module.names.key_vault
  location                        = var.location
  resource_group_name             = var.resource_group_name
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_vm_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = true
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.purge_protection_enabled
  sku_name                        = local.pricing_tier
  public_network_access_enabled   = var.public_network_access_enabled

  network_acls {
    default_action             = "Deny"
    bypass                     = local.network_acls_bypass
    virtual_network_subnet_ids = var.authorized_vnet_subnet_ids
    ip_rules                   = var.authorized_ips_or_cidr_blocks
  }

  tags = local.tags

  lifecycle {
    # Ignored tags which are been set by policy.
    ignore_changes = [
      tags["ownerresgroup"],
      tags["owneremail"],
      tags["costcenter"],
      tags["owner"],
      tags["servicecriticality"],
      tags["env"],
      tags["workload"],
      tags["scope"],
      tags["tier"],
    ]
  }
}

module "lifecycle" {
  source     = "../ccoe.product.tools.lifecycle//module?ref=0.2.0"
  depends_on = [azurerm_key_vault.vault]

  resource_id   = azurerm_key_vault.vault.id
  environment   = var.environment
  workload_name = var.workload_name
}
