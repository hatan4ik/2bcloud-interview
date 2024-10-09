module "names" {
  source          = "../ccoe.product.naming//module?ref=0.11.0"
  environment     = var.environment
  location        = var.location
  workload_name   = var.workload_name
  sequence_number = var.sequence_number
}
