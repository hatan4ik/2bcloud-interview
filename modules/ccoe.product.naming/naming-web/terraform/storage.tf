resource "azurerm_storage_account" "this" {
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  location                  = local.location
  name                      = module.naming.storage_account
  resource_group_name       = azurerm_resource_group.this.name
  account_kind              = "StorageV2"
  enable_https_traffic_only = true

  static_website {
    index_document = "index.html"
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["Logging", "Metrics", "AzureServices"]
    virtual_network_subnet_ids = [data.azurerm_subnet.ado_agents.id]
  }

  tags = azurerm_resource_group.this.tags
}

resource "azurerm_private_endpoint" "storage_web" {
  location            = local.location
  name                = module.private_endpoint_naming.private_endpoint
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = data.azurerm_subnet.this.id
  private_service_connection {
    is_manual_connection           = false
    name                           = module.private_endpoint_naming.private_service_connection
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["web"]
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }

  tags = azurerm_resource_group.this.tags
}