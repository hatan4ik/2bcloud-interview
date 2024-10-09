# Please use the workspace_resolver module if OMS Agent logs should be sent into the Central Log Analytics Workspace.
# This module will retrieve LAW id in Corp tenant for `Development`, `Test`, `Global` or for `Production` environment
# or `Lab` LAW id for Lab environment.
module "workspace_resolver" {
  source = "../ccoe.product.tools.workspaceresolver//module?ref=0.2.0"

  environment = local.environment
}
