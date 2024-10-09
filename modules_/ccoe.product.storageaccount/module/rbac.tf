module "rbac" {
  source = "../ccoe.product.tools.rbac//module?ref=0.2.0"

  role_mapping = [
    {
      role_definition_name = "Storage Blob Data Owner"
      principal_ids        = var.blobdataowner_role_object_ids
    },
    {
      role_definition_name = "Storage Blob Data Reader"
      principal_ids        = var.blobdatareader_role_object_ids
    },
    {
      role_definition_name = "Storage Blob Data Contributor"
      principal_ids        = var.blobdatacontributor_role_object_ids
    },
    {
      role_definition_name = "Storage Queue Data Contributor"
      principal_ids        = var.queuedatacontributor_role_object_ids
    },
    {
      role_definition_name = "Storage Table Data Contributor"
      principal_ids        = var.tabledatacontributor_role_object_ids
    },
    {
      role_definition_name = "Storage Table Data Reader"
      principal_ids        = var.tabledatareader_role_object_ids
    },
    {
      role_definition_name = "Storage File Data SMB Share Contributor"
      principal_ids        = var.filedatasmbsharecontributor_role_object_ids
    },
    {
      role_definition_name = "Storage File Data SMB Share Elevated Contributor"
      principal_ids        = var.filedatasmbshareelevatedcontributor_role_object_ids
    },
    {
      role_definition_name = "Storage File Data SMB Share Reader"
      principal_ids        = var.filedatasmbsharereader_role_object_ids
    },
  ]

  scope_id = azurerm_storage_account.resource.id
}
