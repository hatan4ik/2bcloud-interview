/**
 * # CCoE Storage Account
 *
 * This module will deploy an Azure Storage Account compliant with SES Security and MSM controls.
 */

resource "azurerm_storage_account" "resource" {
  name                              = module.names.storage_account
  resource_group_name               = var.resource_group_name
  location                          = local.location
  account_kind                      = var.account_kind
  account_tier                      = var.account_tier
  access_tier                       = local.access_tier
  account_replication_type          = var.replication_type
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  is_hns_enabled                    = local.allow_hns
  infrastructure_encryption_enabled = var.enable_infrastructure_encryption
  allow_nested_items_to_be_public   = var.enable_blob_anonymous_access
  shared_access_key_enabled         = var.enable_shared_access_keys
  public_network_access_enabled     = var.public_network_access_enabled

  dynamic "identity" {
    for_each = var.customer_managed_keys.cmk_enabled ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.customer_managed_keys.user_managed_identity_id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_keys.cmk_enabled ? [1] : []
    content {
      key_vault_key_id          = var.customer_managed_keys.keyvault_key_id
      user_assigned_identity_id = var.customer_managed_keys.user_managed_identity_id
    }
  }

  dynamic "blob_properties" {
    for_each = var.is_hns_enabled ? [] : [1]
    content {
      change_feed_enabled = local.change_feed_enabled
      versioning_enabled  = var.data_protection.enable_blob_versioning

      dynamic "restore_policy" {
        for_each = var.data_protection.enable_point_in_time_restore ? [1] : []
        content {
          days = var.data_protection.point_in_time_retention_period_in_days
        }
      }

      dynamic "delete_retention_policy" {
        for_each = var.data_protection.enable_blob_soft_delete ? [1] : []
        content {
          days = var.data_protection.deleted_blob_retention_days
        }
      }

      dynamic "cors_rule" {
        for_each = var.cors_rule != null ? [1] : []
        content {
          allowed_headers    = var.cors_rule.allowed_headers
          allowed_methods    = var.cors_rule.allowed_methods
          allowed_origins    = var.cors_rule.allowed_origins
          exposed_headers    = var.cors_rule.exposed_headers
          max_age_in_seconds = var.cors_rule.max_age_in_seconds
        }
      }
    }
  }

  network_rules {
    default_action             = "Deny"
    ip_rules                   = var.authorized_ips_or_cidr_blocks
    virtual_network_subnet_ids = var.authorized_vnet_subnet_ids
    bypass                     = ["AzureServices", "Logging", "Metrics"]
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
      azure_files_authentication["directory_type"],
    ]
  }
}

resource "azurerm_storage_container" "container" {
  for_each = local.container_names
  name     = each.value

  storage_account_name  = azurerm_storage_account.resource.name
  container_access_type = "private"
}

resource "azurerm_storage_queue" "queue" {
  for_each = local.queue_names
  name     = each.value

  storage_account_name = azurerm_storage_account.resource.name
}

resource "azurerm_storage_table" "table" {
  for_each = local.table_names
  name     = each.value

  storage_account_name = azurerm_storage_account.resource.name
  depends_on           = [module.rbac]
}

module "lifecycle" {
  source     = "../ccoe.product.tools.lifecycle//module?ref=0.2.0"
  depends_on = [azurerm_storage_account.resource]

  resource_id   = azurerm_storage_account.resource.id
  environment   = var.environment
  workload_name = var.workload_name
}

resource "azurerm_storage_share" "this" {
  for_each = { for fileshare in var.file_shares : fileshare.name => fileshare }

  name                 = each.value.name
  quota                = each.value.quota
  storage_account_name = azurerm_storage_account.resource.name
}

resource "azurerm_advanced_threat_protection" "this" {
  count = var.azure_defender_enabled ? 1 : 0

  target_resource_id = azurerm_storage_account.resource.id
  enabled            = var.azure_defender_enabled
}
