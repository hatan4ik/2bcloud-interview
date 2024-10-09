
#------------------------------
#   Name of the All resources
#------------------------------
module "k8s_name" {
  source          = "../ccoe.product.naming//module?ref=0.9.0"
  environment     = var.environment
  location        = var.location
  workload_name   = var.workload_name
  sequence_number = var.sequence_number
}
