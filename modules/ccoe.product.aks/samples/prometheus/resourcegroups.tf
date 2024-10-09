resource "azurerm_resource_group" "this" {
  name     = module.names.resource_group
  location = local.location

  tags = local.tags

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
      tags["ownerResGroup"],
    ]
  }
}
