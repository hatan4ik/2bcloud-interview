module "central_workspace_resolver" {
  source      = "../ccoe.product.tools.workspaceresolver//module?ref=0.2.0"
  environment = var.environment
}
