module "names" {
  source          = "../ccoe.product.naming//module?ref=0.9.0"
  environment     = local.environment
  location        = local.location
  workload_name   = random_string.workload_name.result
  sequence_number = 22
}
