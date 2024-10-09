output "virtual_machine_name" {
  description = "The name of the virtual machine."
  value       = azurerm_linux_virtual_machine.virtual_machine.name
}

output "virtual_machine_id" {
  description = "The ID of the virtual machine."
  value       = azurerm_linux_virtual_machine.virtual_machine.id
}

output "data_disk_name" {
  description = "The name of the data disks of the virtual machine."
  value       = values(azurerm_managed_disk.data_disk)[*].name
}

output "os_disk_name" {
  description = "The name of the OS disk of the virtual machine."
  value       = azurerm_linux_virtual_machine.virtual_machine.os_disk[0].name
}

output "nic_name" {
  description = "The name of the network interface card of the virtual machine."
  value       = azurerm_network_interface.nic.name
}

output "user_assigned_ids" {
  description = "The list of user assigned managed identities for the Linux VM."
  value       = azurerm_linux_virtual_machine.virtual_machine.*.identity
}

output "nic_id" {
  description = "The name of the network interface card of the virtual machine."
  value       = azurerm_network_interface.nic.id
}

output "private_ip" {
  description = "The private IP of the virtual machine."
  value       = azurerm_network_interface.nic.private_ip_addresses[0]
}

output "network_watcher_extension_name" {
  description = "The name of the network watcher extension of the virtual machine."
  value       = azurerm_virtual_machine_extension.network_watcher.name
}

output "identity_ids" {
  description = "Identity ids associated with this Virtual machine"
  value       = azurerm_linux_virtual_machine.virtual_machine.identity[0].identity_ids
}
