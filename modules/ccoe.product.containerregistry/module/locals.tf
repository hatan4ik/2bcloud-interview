locals {
  default_tags = { CCoEProdVersion = "ACRv4.2.0" }
  tags         = merge(var.optional_tags, local.default_tags)
}
