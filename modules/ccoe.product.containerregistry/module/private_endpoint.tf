resource "azurerm_private_endpoint" "private_endpoint" {
  for_each = var.private_endpoint

  name                = module.private_endpoints_names[each.key].private_endpoint
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.optional_tags, local.default_tags)
  subnet_id           = var.private_endpoint[each.key].subnet_id

  dynamic "ip_configuration" {
    for_each = var.private_endpoint[each.key].ip_configuration
    iterator = config
    content {
      name               = "${module.private_endpoints_names[each.key].ip_configuration}-${config.value["member_name"]}"
      private_ip_address = config.value["private_ip_address"]
      member_name        = config.value["member_name"]
      subresource_name   = "registry"
    }
  }

  private_service_connection {
    name                           = module.private_endpoints_names[each.key].private_service_connection
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  lifecycle {
    ignore_changes = [
      private_dns_zone_group,
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

  depends_on = [module.private_endpoints_names]
}
