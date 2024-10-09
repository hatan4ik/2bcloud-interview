resource "azurerm_private_endpoint" "private_endpoint" {
  for_each = var.private_endpoint

  name                = module.private_endpoint_names[each.key].private_endpoint
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint[each.key].subnet_id
  tags                = local.tags

  dynamic "ip_configuration" {
    for_each = var.private_endpoint[each.key].private_ip_address != null ? [1] : []
    content {
      name               = module.private_endpoint_names[each.key].ip_configuration
      private_ip_address = var.private_endpoint[each.key].private_ip_address
      member_name        = "default"
      subresource_name   = "vault"
    }
  }

  private_service_connection {
    name                           = module.private_endpoint_names[each.key].private_service_connection
    private_connection_resource_id = azurerm_key_vault.vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group, tags]
  }
}
