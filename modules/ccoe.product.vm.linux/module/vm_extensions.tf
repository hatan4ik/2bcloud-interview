resource "azurerm_virtual_machine_extension" "network_watcher" {
  name                 = module.names.0.virtual_machine_extension
  virtual_machine_id   = azurerm_linux_virtual_machine.virtual_machine.id
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentLinux"
  type_handler_version = "1.4"

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.attachment
  ]

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
