<!-- BEGIN_TF_DOCS -->
# CCoE Storage Account

This module will deploy an Azure Storage Account compliant with SES Security and MSM controls.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >=1.6.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.114.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >=3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.114.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >=3.0.0 |

## Sample

<details>
<summary>Click to expand</summary>

```hcl
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
```
### For a complete deployment example, please check [sample folder](/samples).
</details>

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tier"></a> [access\_tier](#input\_access\_tier) | Specifies the access tier for StorageV2 accounts. Valid options are Hot and Cool. | `string` | `"Hot"` | no |
| <a name="input_account_kind"></a> [account\_kind](#input\_account\_kind) | Defines the Kind of account. Valid options are BlockBlobStorage and StorageV2. Defaults to StorageV2. Important note: if the storage account already exists and the new value does NOT support `access_tier` variable, you must remove the storage account. | `string` | `"StorageV2"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | The tier to be used for Storage Account. Valid options are Standard and Premium. | `string` | `"Standard"` | no |
| <a name="input_authorized_ips_or_cidr_blocks"></a> [authorized\_ips\_or\_cidr\_blocks](#input\_authorized\_ips\_or\_cidr\_blocks) | List of authorized IP addresses or CIDR Blocks to allow access from. | `list(string)` | `[]` | no |
| <a name="input_authorized_vnet_subnet_ids"></a> [authorized\_vnet\_subnet\_ids](#input\_authorized\_vnet\_subnet\_ids) | IDs of the virtual network subnets authorized to connect to the Storage Account. | `list(string)` | `[]` | no |
| <a name="input_azure_defender_enabled"></a> [azure\_defender\_enabled](#input\_azure\_defender\_enabled) | Is Azure Defender enabled for this Azure Storage Account? | `bool` | `false` | no |
| <a name="input_backup_vault"></a> [backup\_vault](#input\_backup\_vault) | Backup Vault to perform backup related operations on storage account Blobs. This block requires the following inputs:<br> - `id`: Backup Vault id. <br> - `system_assigned_id`: Principle id of backup vault's system assigned identity. <br> Kindly note: this will enable `Operational backup` and `Vaulted Backup` still in public preview. | <pre>object({<br>    id                 = string<br>    system_assigned_id = string<br>  })</pre> | `null` | no |
| <a name="input_blobdatacontributor_role_object_ids"></a> [blobdatacontributor\_role\_object\_ids](#input\_blobdatacontributor\_role\_object\_ids) | List of Service Principal or group object IDs to be added with contributor role on Storage Account. | `list(string)` | `[]` | no |
| <a name="input_blobdataowner_role_object_ids"></a> [blobdataowner\_role\_object\_ids](#input\_blobdataowner\_role\_object\_ids) | List of Service Principal or group object IDs to be added with owner role on Storage Account. | `list(string)` | `[]` | no |
| <a name="input_blobdatareader_role_object_ids"></a> [blobdatareader\_role\_object\_ids](#input\_blobdatareader\_role\_object\_ids) | List of Service Principal or group object IDs to be added with reader role on Storage Account. | `list(string)` | `[]` | no |
| <a name="input_container_names"></a> [container\_names](#input\_container\_names) | Names of the blob containers to create. | `list(string)` | `[]` | no |
| <a name="input_cors_rule"></a> [cors\_rule](#input\_cors\_rule) | Settings related to CORS. This block requires the following inputs:<br> - `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request. <br> - `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are DELETE, GET, HEAD, MERGE, POST, OPTIONS, PUT or PATCH. <br> - `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS. <br> - `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients. <br> - `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response. | <pre>object({<br>    allowed_headers    = list(string)<br>    allowed_methods    = list(string)<br>    allowed_origins    = list(string)<br>    exposed_headers    = list(string)<br>    max_age_in_seconds = number<br>  })</pre> | `null` | no |
| <a name="input_customer_managed_keys"></a> [customer\_managed\_keys](#input\_customer\_managed\_keys) | Specifies customer managed keys configuration. This block requires the following inputs:<br> - `cmk_enabled`: If Customer Managed Key needs to be enabled?<br> - `user_managed_identity` Managed Identity that will be assigned to the File Storage. <br> - `keyvault_id` Key Vault's id where the key will be stored. | <pre>object({<br>    cmk_enabled              = bool<br>    user_managed_identity_id = string<br>    keyvault_key_id          = string<br>  })</pre> | <pre>{<br>  "cmk_enabled": false,<br>  "keyvault_key_id": "",<br>  "user_managed_identity_id": ""<br>}</pre> | no |
| <a name="input_data_protection"></a> [data\_protection](#input\_data\_protection) | Data protection configuration information. When provided, this block accepts the following inputs:<br>  - `enable_blob_soft_delete`: Flag to enable or not blob soft delete feature.<br>  - `deleted_blob_retention_days`: Specifies the number of days that the blob should be retained, between 1 and 365.<br>  - `enable_blob_versioning`: Flag to enable or not blob versioning.<br>  - `enable_point_in_time_restore`: Flag to enable or not point in time restore. If set to true, container\_delete\_retention\_in\_days must be provided if you need more than 7 days retention and requires soft delete, blob versioning and change feed to be enabled as well.<br>  - `point_in_time_retention_period_in_days`: Specifies the number of days that point in time restore is possible. This value should be at least 1 day less than soft delete retention period.<br>  - `enable_change_feed`: Flag to enable or not change feed. | <pre>object({<br>    enable_blob_soft_delete                = bool<br>    deleted_blob_retention_days            = number<br>    enable_blob_versioning                 = bool<br>    point_in_time_retention_period_in_days = number<br>    enable_point_in_time_restore           = bool<br>    enable_change_feed                     = bool<br>  })</pre> | <pre>{<br>  "deleted_blob_retention_days": 8,<br>  "enable_blob_soft_delete": true,<br>  "enable_blob_versioning": false,<br>  "enable_change_feed": false,<br>  "enable_point_in_time_restore": false,<br>  "point_in_time_retention_period_in_days": 7<br>}</pre> | no |
| <a name="input_enable_blob_anonymous_access"></a> [enable\_blob\_anonymous\_access](#input\_enable\_blob\_anonymous\_access) | Allow or disallow nested items within this Account to opt into being public. Anonymous access presents a potential security risk, so if your scenario does not require it, we recommend that you remediate anonymous access for the storage account. | `bool` | `false` | no |
| <a name="input_enable_infrastructure_encryption"></a> [enable\_infrastructure\_encryption](#input\_enable\_infrastructure\_encryption) | Is infrastructure encryption enabled? Changing this forces a new resource to be created. | `bool` | `true` | no |
| <a name="input_enable_shared_access_keys"></a> [enable\_shared\_access\_keys](#input\_enable\_shared\_access\_keys) | Does the Storage Account permit requests to be authorized with the account access key via Shared Key? If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development', 'Production' and 'Global'. | `string` | n/a | yes |
| <a name="input_file_shares"></a> [file\_shares](#input\_file\_shares) | The options for the storage file share. File Share can be created only for Standard Tier. This block requires the following inputs: <br>  - `name`: The name of the storage file share. The name length should be between 3 and 63 chars. The name can contain only lowercase letters, numbers, and hyphens, and must begin and end with a letter or a number. The name cannot contain two consecutive hyphens.<br>  - `quota`: The quota of the storage file share. The quota must be between 1 and 5120 GiB. | <pre>list(object({<br>    name  = string<br>    quota = number<br>  }))</pre> | `[]` | no |
| <a name="input_filedatasmbsharecontributor_role_object_ids"></a> [filedatasmbsharecontributor\_role\_object\_ids](#input\_filedatasmbsharecontributor\_role\_object\_ids) | List of Service Principal or group object IDs to be added with File Data SMB Share Contributor on Storage Account. | `list(string)` | `[]` | no |
| <a name="input_filedatasmbshareelevatedcontributor_role_object_ids"></a> [filedatasmbshareelevatedcontributor\_role\_object\_ids](#input\_filedatasmbshareelevatedcontributor\_role\_object\_ids) | List of Service Principal or group object IDs to be added with File Data SMB Share Elevated Contributor on Storage Account. | `list(string)` | `[]` | no |
| <a name="input_filedatasmbsharereader_role_object_ids"></a> [filedatasmbsharereader\_role\_object\_ids](#input\_filedatasmbsharereader\_role\_object\_ids) | List of Service Principal or group object IDs to be added with File Data SMB Share Reader on Storage Account. | `list(string)` | `[]` | no |
| <a name="input_immutability_policy"></a> [immutability\_policy](#input\_immutability\_policy) | To configure a time-based retention policy on a container. This block requires the following inputs:<br> - `container_name`: Container to configure a time-based retention policy. <br> - `period_in_days` You can configure a container-level retention policy for between 1 and 146000 days. | <pre>object({<br>    container_name = string<br>    period_in_days = number<br>  })</pre> | `null` | no |
| <a name="input_is_hns_enabled"></a> [is\_hns\_enabled](#input\_is\_hns\_enabled) | Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2. This is supported only for Standard account\_tier. | `bool` | `false` | no |
| <a name="input_legal_hold_policy"></a> [legal\_hold\_policy](#input\_legal\_hold\_policy) | A legal hold stores immutable data until the legal hold is explicitly cleared. This block requires the following inputs:<br> - `container_name`: Container to configure legal hold. <br> - `tag` Defines the tag for this lock. Tag name should be 3 to 23 alphanumeric characters. | <pre>object({<br>    container_name = string<br>    tag            = string<br>  })</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive). | `string` | n/a | yes |
| <a name="input_optional_tags"></a> [optional\_tags](#input\_optional\_tags) | Optional tags for the Azure Storage Account. Please set a value for the key `supportResGroup` when support is not provided by the ownerResGroup team, but by a specialized team (such as IT Systems Operations, IT Network Operations, etc.). This tag should be defined, when required,on each CCoE product template (IaC), and applied automatically during deployment. Typically, a Distribution List to enable sending relevant notifications and information (e.g. in case of incidents, planned maintenances, new available components) from Azure or also the ITSM tool. Tag value will be requested and provided during the workload intake process. | `map(string)` | `{}` | no |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | Specifies the private endpoint details for Storage Account. This block requires the following inputs:<br> - `subnet_id`: The id of the subnet used for private endpoint.<br> - `resource_type`: The type of private end point. Valid values are `blob`, `table`, `queue` or `file`.<br> private\_ip\_address (Optional): Private IP Address assign to the Private Endpoint. The last one and first four IPs in any range are reserved and cannot be manually assigned. | <pre>map(object({<br>    subnet_id          = string<br>    resource_type      = string<br>    private_ip_address = optional(string)<br>  }))</pre> | `{}` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Enable public access from specific virtual networks and IP addresses. When the value is `false`, clients can only use the private endpoint to communicate with the storage. | `bool` | `true` | no |
| <a name="input_queue_names"></a> [queue\_names](#input\_queue\_names) | Names of the queues to create. | `list(string)` | `[]` | no |
| <a name="input_queuedatacontributor_role_object_ids"></a> [queuedatacontributor\_role\_object\_ids](#input\_queuedatacontributor\_role\_object\_ids) | List of Service Principal or group object IDs to be added with queue data contributor role on Storage Account. | `list(string)` | `[]` | no |
| <a name="input_replication_type"></a> [replication\_type](#input\_replication\_type) | Defines the type of replication to use for this storage account. Valid options are LRS, GRS and RAGRS. | `string` | `"LRS"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The resource group where to deploy the storage account. | `string` | n/a | yes |
| <a name="input_sequence_number"></a> [sequence\_number](#input\_sequence\_number) | When using count on the module, you should provide a sequence number that will be the storage account name suffix. It must be an integer. | `number` | `1` | no |
| <a name="input_table_names"></a> [table\_names](#input\_table\_names) | Names of the tables to create. | `list(string)` | `[]` | no |
| <a name="input_tabledatacontributor_role_object_ids"></a> [tabledatacontributor\_role\_object\_ids](#input\_tabledatacontributor\_role\_object\_ids) | List of Service Principal or group object IDs to be added with table data contributor role on Storage Account. | `list(string)` | `[]` | no |
| <a name="input_tabledatareader_role_object_ids"></a> [tabledatareader\_role\_object\_ids](#input\_tabledatareader\_role\_object\_ids) | List of Service Principal or group object IDs to be added with table data reader role on Storage Account. | `list(string)` | `[]` | no |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | Specifies the workload name that will use this resource. This will be used in the resource name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ATP_id"></a> [ATP\_id](#output\_ATP\_id) | The Advanced Threat Protection id. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the created Azure storage account resource. |
| <a name="output_name"></a> [name](#output\_name) | The name of the created Azure storage account resource. |
| <a name="output_primary_access_key"></a> [primary\_access\_key](#output\_primary\_access\_key) | The primary\_access\_key of the created Azure storage account resource. |
| <a name="output_primary_blob_endpoint"></a> [primary\_blob\_endpoint](#output\_primary\_blob\_endpoint) | The primary\_blob\_endpoint of the created Azure storage account resource. |
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) | The private endpoint Id of Storage account |
| <a name="output_private_endpoint_name"></a> [private\_endpoint\_name](#output\_private\_endpoint\_name) | The private endpoint name of Storage account |

## Resources

| Name | Type |
|------|------|
| [azurerm_advanced_threat_protection.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/advanced_threat_protection) | resource |
| [azurerm_data_protection_backup_instance_blob_storage.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_instance_blob_storage) | resource |
| [azurerm_data_protection_backup_policy_blob_storage.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_policy_blob_storage) | resource |
| [azurerm_private_endpoint.private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_queue.queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_queue) | resource |
| [azurerm_storage_share.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [azurerm_storage_table.table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_table) | resource |
| [null_resource.immutable_policy](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.legal_hold_policy](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lifecycle"></a> [lifecycle](#module\_lifecycle) | ../ccoe.product.tools.lifecycle//module | 0.2.0 |
| <a name="module_names"></a> [names](#module\_names) | ../ccoe.product.naming//module | 0.10.0 |
| <a name="module_private_endpoint_names"></a> [private\_endpoint\_names](#module\_private\_endpoint\_names) | ../ccoe.product.naming//module | 0.10.0 |
| <a name="module_rbac"></a> [rbac](#module\_rbac) | ../ccoe.product.tools.rbac//module | 0.2.0 |
<!-- END_TF_DOCS -->