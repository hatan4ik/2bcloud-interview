resource "azurerm_managed_disk" "data_disk" {
  for_each = var.data_disk_config

  location               = var.location
  resource_group_name    = var.resource_group_name
  name                   = module.data_disk_names[each.key].virtual_machine_data_disk
  zone                   = tostring(var.azure_availability_zone)
  storage_account_type   = each.value.storage_account_type
  create_option          = "Empty"
  disk_size_gb           = each.value.size
  disk_encryption_set_id = var.disk_encryption_set_id

  tags = merge(var.optional_tags, local.default_tags)
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

resource "azurerm_virtual_machine_data_disk_attachment" "attachment" {
  for_each = var.data_disk_config

  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.virtual_machine.id
  lun                = index(keys(var.data_disk_config), each.key) + 1
  caching            = "ReadWrite"
}
