module "storage" {
  # Please update the module's source as indicated below:
  # source = "../ccoe.product.storageaccount//module?ref=4.1.0"
  source = "../module"

  resource_group_name = azurerm_resource_group.group.name
  environment         = local.environment
  workload_name       = random_string.workload_name.result
  location            = local.location
  replication_type    = "ZRS"

  #If needed, the Access Keys can be disabled, by setting enable_shared_access_keys = false. This allows using the RBAC
  #sub-resource level (blob/table/queue/fileshare) and to restrict the access based on separation of duties.
  #This is now supported for **blobs and tables only**.
  enable_shared_access_keys = true

  #Storage sub-resources:
  container_names = ["container1", "container2"]
  table_names     = ["queuetable"]
  queue_names     = ["queue-sample"]
  file_shares = [
    {
      name  = "abc"
      quota = 20
    },
    {
      name  = "efghdbvhjv",
      quota = 100
    }
  ]
  ##Data protection conflicts with immutable_policy
  data_protection = {
    enable_blob_soft_delete                = true
    deleted_blob_retention_days            = 8
    enable_blob_versioning                 = true
    point_in_time_retention_period_in_days = 7
    enable_point_in_time_restore           = true
    enable_change_feed                     = true
  }

  #Storage Account Firewall configuration. Please adapt this to your environment.
  authorized_ips_or_cidr_blocks = [local.test_host_ip]
  authorized_vnet_subnet_ids    = [data.azurerm_subnet.ado_agents.id]

  #Possible RBAC role assignemnts. Please assign the ones necessary for your deployment.
  blobdatareader_role_object_ids                      = [data.azurerm_client_config.current.object_id]
  blobdataowner_role_object_ids                       = [data.azurerm_client_config.current.object_id]
  blobdatacontributor_role_object_ids                 = [data.azurerm_client_config.current.object_id, "234126a4-1d31-4f6c-8a74-f4ee17356c1a"]
  queuedatacontributor_role_object_ids                = [data.azurerm_client_config.current.object_id]
  tabledatacontributor_role_object_ids                = [data.azurerm_client_config.current.object_id]
  filedatasmbsharecontributor_role_object_ids         = [data.azurerm_client_config.current.object_id]
  filedatasmbshareelevatedcontributor_role_object_ids = [data.azurerm_client_config.current.object_id]
  filedatasmbsharereader_role_object_ids              = [data.azurerm_client_config.current.object_id]

  #Private endpoints resources. Please adapt this to your environment.
  private_endpoint = {
    "my_file_pep" = {
      subnet_id     = data.azurerm_subnet.spoke.id
      resource_type = "file"
      //private_ip_address = "10.57.50.57"
    }

    "my_blob_pep" = {
      subnet_id     = data.azurerm_subnet.spoke.id
      resource_type = "blob"
      //private_ip_address = "10.57.50.58"
    },
    "my_queue_pep" = {
      subnet_id     = data.azurerm_subnet.spoke.id
      resource_type = "queue"
    }
    "my_table_pep" = {
      subnet_id     = data.azurerm_subnet.spoke.id
      resource_type = "table"
    }
  }

  #  ## immutable_policy conflicts with Data protection
  #  immutability_policy = {
  #    container_name = "container1"
  #    period_in_days = 180
  #  }
  #  legal_hold_policy = {
  #    container_name = "container2"
  #    tag            = "testtag"
  #  }

  cors_rule = {
    allowed_headers    = ["x-ms-meta-data*", "x-ms-meta-target*", "x-ms-meta-abc"]
    allowed_methods    = ["DELETE", "GET", "POST", "OPTIONS", "PUT", "PATCH"]
    allowed_origins    = ["http://*.contoso.com"]
    exposed_headers    = ["x-ms-meta-*"]
    max_age_in_seconds = 86400
  }

  #  #Storage blob backup options
  #  backup_vault = {
  #    id                 = azurerm_data_protection_backup_vault.this.id
  #    system_assigned_id = azurerm_data_protection_backup_vault.this.identity[0].principal_id
  #  }
}
