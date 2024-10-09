module "names" {
  count = 2

  source          = "../ccoe.product.naming//module?ref=0.9.0"
  environment     = var.environment
  location        = var.location
  workload_name   = var.workload_name
  sequence_number = var.sequence_number

  sub_resource_sequence_number = count.index + 1
}

module "data_disk_names" {
  for_each = var.data_disk_config

  source          = "../ccoe.product.naming//module?ref=0.9.0"
  environment     = var.environment
  location        = var.location
  workload_name   = var.workload_name
  sequence_number = var.sequence_number

  sub_resource_sequence_number = (index(keys(var.data_disk_config), each.key) + 1)
}
