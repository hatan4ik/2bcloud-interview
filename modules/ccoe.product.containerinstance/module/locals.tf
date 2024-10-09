locals {
  default_tags = { CCoEProdVersion = "ACIv2.3.0" }
  tags         = merge(var.optional_tags, local.default_tags)
}
