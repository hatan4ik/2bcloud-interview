module "rbac" {
  source = "../ccoe.product.tools.rbac//module?ref=0.2.0"

  role_mapping = [
    {
      role_definition_name = "AcrPull"
      principal_ids        = var.image_pull_service_principal_ids
    },
    {
      role_definition_name = "AcrPush"
      principal_ids        = var.image_push_service_principal_ids
    },
  ]

  scope_id = azurerm_container_registry.acr.id
}
