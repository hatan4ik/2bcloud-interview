locals {
  environment_identifier                  = lower(substr(var.environment, 0, 1))
  location_identifier                     = lookup({ "westeurope" = "weu1", "eastus" = "eus1", "eastus2" = "eus2", "global" = "glob", "centralus" = "cus1", "northeurope" = "neu1", "southeastasia" = "sea1", "uksouth" = "uks1", "centralindia" = "cin1" }, lower(replace(var.location, " ", "")))
  sequence_number                         = format("%03d", var.sequence_number)
  two_digits_sequence_number              = format("%02d", var.sequence_number)
  two_digits_sub_resource_sequence_number = format("%02d", var.sub_resource_sequence_number)
  default_workload_name                   = substr(var.workload_name, 0, 9)
  ten_char_suffix                         = substr(var.suffix, 0, 10)
  eight_char_workload_name                = substr(var.workload_name, 0, 8)
  fifteen_char_suffix                     = substr(var.suffix, 0, 15)
  eight_char_suffix                       = substr(var.suffix, 0, 8)

  private_endpoint_subnet_prefix            = length(var.private_endpoint_subnet_name) == 0 ? "" : substr(var.private_endpoint_subnet_name, 0, 3)
  private_endpoint_subnet_sequence_number   = length(var.private_endpoint_subnet_name) == 0 ? "" : split("-", var.private_endpoint_subnet_name)[4]
  private_endpoint_source_identifier        = "${local.private_endpoint_subnet_prefix}${local.private_endpoint_subnet_sequence_number}"
  private_endpoint_resource_name_length     = length(var.private_endpoint_resource_name)
  private_endpoint_resource_prefix          = substr(var.private_endpoint_resource_name, 0, 3)
  private_endpoint_resource_sequence_number = substr(var.private_endpoint_resource_name, local.private_endpoint_resource_name_length - 3, local.private_endpoint_resource_name_length - 1)
  private_endpoint_destination_identifier   = "${local.private_endpoint_resource_prefix}${local.private_endpoint_resource_sequence_number}"
  private_endpoint_source_destination_part  = "${local.private_endpoint_source_identifier}-${local.private_endpoint_destination_identifier}"

  conventions = {
    default                    = "-${local.default_workload_name}-${local.location_identifier}-${local.environment_identifier}-${local.sequence_number}"
    default_with_suffix        = "-${local.default_workload_name}-${local.location_identifier}-${local.environment_identifier}-${local.sequence_number}-${local.ten_char_suffix}"
    default_without_dashes     = "${local.default_workload_name}${local.location_identifier}${local.environment_identifier}${local.sequence_number}"
    virtual_machine            = "${local.default_workload_name}${local.environment_identifier}${local.sequence_number}"
    private_endpoint           = "-${local.private_endpoint_source_destination_part}-${local.default_workload_name}-${local.location_identifier}-${local.environment_identifier}"
    service_principal          = "-${var.workload_name}-${local.environment_identifier}-${local.two_digits_sequence_number}"
    management_group           = "-${local.eight_char_workload_name}"
    subscription               = "-${local.eight_char_workload_name}-${local.environment_identifier}-${local.ten_char_suffix}-${local.two_digits_sequence_number}"
    network_security_group     = "-${local.fifteen_char_suffix}"
    health_alert               = "_${var.subscription_name}_${var.suffix}"
    action_group               = "_${local.eight_char_suffix}"
    diagnostic_settings_suffix = "_${local.two_digits_sequence_number}"
  }
}
