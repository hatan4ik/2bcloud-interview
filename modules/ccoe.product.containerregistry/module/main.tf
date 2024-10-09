/**
 * # CCoE Azure Container Registry
 *
 * This module will deploy an Azure Container Registry compliant with SES Security and MSM controls.
 */

resource "azurerm_container_registry" "acr" {
  name                          = module.names.container_registry
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  public_network_access_enabled = true

  dynamic "georeplications" {
    for_each = var.georeplication_locations != null ? var.georeplication_locations : []

    content {
      location                = georeplications.value
      zone_redundancy_enabled = true
    }
  }

  dynamic "network_rule_set" {
    for_each = var.private_endpoint
    content {
      default_action = "Deny"
    }
  }

  dynamic "identity" {
    for_each = var.customer_managed_keys.cmk_enabled ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.customer_managed_keys.user_managed_identity_id]
    }
  }

  dynamic "encryption" {
    for_each = var.customer_managed_keys.cmk_enabled ? [1] : []
    content {
      enabled            = true
      key_vault_key_id   = var.customer_managed_keys.kvt_key_id
      identity_client_id = var.customer_managed_keys.user_managed_identity_clientid
    }
  }

  tags = local.tags

  lifecycle {
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
  depends_on = [azurerm_container_registry.acr]

  resource_id   = azurerm_container_registry.acr.id
  environment   = var.environment
  workload_name = var.workload_name
}
