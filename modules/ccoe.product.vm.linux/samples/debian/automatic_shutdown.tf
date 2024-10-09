resource "azurerm_dev_test_global_vm_shutdown_schedule" "this" {
  virtual_machine_id = module.certified_vm.virtual_machine_id
  location           = local.location
  #Enables or disables the automatic shutdown for CCoE Linux Virtual Machine.
  enabled               = true
  daily_recurrence_time = "1700"
  timezone              = "Central Europe Standard Time"

  #As we don't configure notification settings but this input is mandatory, it's set on false for this sample.
  notification_settings {
    enabled = false
  }
}
