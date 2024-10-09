module "role_assignment" {
  source = "../ccoe.product.tools.rbac//module?ref=0.2.0"

  role_mapping = [
    {
      role_definition_name = "Classic Virtual Machine Contributor"
      principal_ids        = var.classic_contributor_role_object_ids
    },
    {
      role_definition_name = "Virtual Machine Administrator Login"
      principal_ids        = var.administrator_role_object_ids
    },
    {
      role_definition_name = "Virtual Machine Contributor"
      principal_ids        = var.contributor_role_object_ids
    },
    {
      role_definition_name = "Virtual Machine User Login"
      principal_ids        = var.user_role_object_ids
    }
  ]

  scope_id = azurerm_linux_virtual_machine.virtual_machine.id

}
