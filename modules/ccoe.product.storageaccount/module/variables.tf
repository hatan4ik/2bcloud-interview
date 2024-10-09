variable "resource_group_name" {
  type        = string
  description = "The resource group where to deploy the storage account."
}

variable "replication_type" {
  type        = string
  description = "Defines the type of replication to use for this storage account. Valid options are LRS, GRS and RAGRS."
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS"], var.replication_type)
    error_message = "Invalid replication type. Valid options for replication_type are LRS, ZRS, GRS and RAGRS."
  }
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive)."
}

variable "workload_name" {
  type        = string
  description = "Specifies the workload name that will use this resource. This will be used in the resource name."
}

variable "environment" {
  type        = string
  description = "Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development', 'Production' and 'Global'."
}

variable "access_tier" {
  type        = string
  description = "Specifies the access tier for StorageV2 accounts. Valid options are Hot and Cool."
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Invalid access tier. Environment must have one of the following values (case sensitive): [\"Hot\", \"Cool\"]."
  }
}

variable "private_endpoint" {
  type = map(object({
    subnet_id          = string
    resource_type      = string
    private_ip_address = optional(string)
  }))
  description = "Specifies the private endpoint details for Storage Account. This block requires the following inputs:\n - `subnet_id`: The id of the subnet used for private endpoint.\n - `resource_type`: The type of private end point. Valid values are `blob`, `table`, `queue` or `file`.\n private_ip_address (Optional): Private IP Address assign to the Private Endpoint. The last one and first four IPs in any range are reserved and cannot be manually assigned."
  default     = {} # default to {} is used to avoid creating resource through for_each (equivalent to count = 0)
}

variable "authorized_ips_or_cidr_blocks" {
  type        = list(string)
  description = "List of authorized IP addresses or CIDR Blocks to allow access from."
  default     = []
}

variable "sequence_number" {
  type        = number
  description = "When using count on the module, you should provide a sequence number that will be the storage account name suffix. It must be an integer."
  default     = 1
}

variable "container_names" {
  type        = list(string)
  description = "Names of the blob containers to create."
  default     = []

  validation {
    condition = (
      length([for container_name in var.container_names
        : 1 if
        length(container_name) >= 3
        && length(container_name) <= 63
        && can(regex("^(([a-z0-9]+-?){2,}[a-z0-9]+|[0-9a-z]-[0-9a-z])$", container_name))
      ]) == length(var.container_names)
    )

    error_message = "Invalid container name. Container name must be lowercase alphanumeric with a length of minimum of 3 to maximum 63 characters, with hyphens allowed if not starting or ending the container name."
  }
}

variable "queue_names" {
  type        = list(string)
  description = "Names of the queues to create."
  default     = []

  validation {
    condition = (
      length([for queue_name in var.queue_names
        : 1 if
        length(queue_name) >= 3
        && length(queue_name) <= 63
        && can(regex("^(([a-z0-9]+-?){2,}[a-z0-9]+|[0-9a-z]-[0-9a-z])$", queue_name))
      ]) == length(var.queue_names)
    )

    error_message = "Invalid queue name. Queue name must be lowercase alphanumeric with a length of minimum of 3 to maximum 63 characters, with hyphens allowed if not starting or ending the queue name."
  }
}

variable "table_names" {
  type        = list(string)
  description = "Names of the tables to create."
  default     = []

  validation {
    condition = (
      length([for table_name in var.table_names
        : 1 if
        length(table_name) >= 3
        && length(table_name) <= 63
        && can(regex("^(([a-z0-9]){2,})$", table_name))
      ]) == length(var.table_names)
    )

    error_message = "Invalid table name. Table name  must start with a letter, must contain only alphanumeric characters and must be between 3 and 63 characters long."
  }
}

variable "authorized_vnet_subnet_ids" {
  type        = list(string)
  description = "IDs of the virtual network subnets authorized to connect to the Storage Account."
  default     = []
}

variable "data_protection" {
  type = object({
    enable_blob_soft_delete                = bool
    deleted_blob_retention_days            = number
    enable_blob_versioning                 = bool
    point_in_time_retention_period_in_days = number
    enable_point_in_time_restore           = bool
    enable_change_feed                     = bool
  })
  description = "Data protection configuration information. When provided, this block accepts the following inputs:\n  - `enable_blob_soft_delete`: Flag to enable or not blob soft delete feature.\n  - `deleted_blob_retention_days`: Specifies the number of days that the blob should be retained, between 1 and 365.\n  - `enable_blob_versioning`: Flag to enable or not blob versioning.\n  - `enable_point_in_time_restore`: Flag to enable or not point in time restore. If set to true, container_delete_retention_in_days must be provided if you need more than 7 days retention and requires soft delete, blob versioning and change feed to be enabled as well.\n  - `point_in_time_retention_period_in_days`: Specifies the number of days that point in time restore is possible. This value should be at least 1 day less than soft delete retention period.\n  - `enable_change_feed`: Flag to enable or not change feed."
  default = {
    enable_blob_soft_delete                = true
    deleted_blob_retention_days            = 8
    enable_blob_versioning                 = false
    point_in_time_retention_period_in_days = 7
    enable_point_in_time_restore           = false
    enable_change_feed                     = false
  }

  validation {
    condition = (
      var.data_protection == null ||
      var.data_protection != null && var.data_protection.enable_blob_soft_delete == false &&
      var.data_protection.deleted_blob_retention_days == 0 ||
      var.data_protection != null &&
      var.data_protection.enable_blob_soft_delete
      && can(regex("^[[:digit:]]{1,3}$", var.data_protection.deleted_blob_retention_days))
      && var.data_protection.deleted_blob_retention_days >= 1
      && var.data_protection.deleted_blob_retention_days <= 365
    )
    error_message = "Invalid data protection configuration. When blob soft delete is enabled, `deleted_blob_retention_days` must be an integer between 1 and 365."
  }

  validation {
    condition = (
      var.data_protection == null ||
      var.data_protection.enable_point_in_time_restore == false ||
      (
        var.data_protection.enable_point_in_time_restore &&
        var.data_protection.point_in_time_retention_period_in_days <= var.data_protection.deleted_blob_retention_days - 1 &&
        var.data_protection.enable_blob_soft_delete &&
        var.data_protection.enable_blob_versioning &&
        var.data_protection.enable_change_feed
      )
    )
    error_message = "Invalid point in time restore configuration. To enable container delete feature, blob versioning, soft delete and change feed need to be enabled as well. Moreover, must be 1 day less than `deleted_blob_retention_days`."
  }
}

variable "blobdataowner_role_object_ids" {
  type        = list(string)
  description = "List of Service Principal or group object IDs to be added with owner role on Storage Account."

  validation {
    condition = (
      length([for object_id in var.blobdataowner_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.blobdataowner_role_object_ids)
    )
    error_message = "Invalid object IDs. Blob data owner role object IDs must be valid GUIDs."
  }
  default = []
}

variable "blobdatareader_role_object_ids" {
  type        = list(string)
  description = "List of Service Principal or group object IDs to be added with reader role on Storage Account."
  default     = []

  validation {
    condition = (
      length([for object_id in var.blobdatareader_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.blobdatareader_role_object_ids)
    )
    error_message = "Invalid object IDs. Blob data reader role object IDs must be valid GUIDs."
  }
}

variable "blobdatacontributor_role_object_ids" {
  type        = list(string)
  description = "List of Service Principal or group object IDs to be added with contributor role on Storage Account."
  default     = []

  validation {
    condition = (
      length([for object_id in var.blobdatacontributor_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.blobdatacontributor_role_object_ids)
    )
    error_message = "Invalid object IDs. Blob data contributor role object IDs must be valid GUIDs."
  }
}

variable "queuedatacontributor_role_object_ids" {
  type        = list(string)
  description = "List of Service Principal or group object IDs to be added with queue data contributor role on Storage Account."
  default     = []

  validation {
    condition = (
      length([for object_id in var.queuedatacontributor_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.queuedatacontributor_role_object_ids)
    )
    error_message = "Invalid object IDs. Queue data contributor role object IDs must be valid GUIDs."
  }
}

variable "tabledatacontributor_role_object_ids" {
  type        = list(string)
  description = "List of Service Principal or group object IDs to be added with table data contributor role on Storage Account."
  default     = []

  validation {
    condition = (
      length([for object_id in var.tabledatacontributor_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.tabledatacontributor_role_object_ids)
    )
    error_message = "Invalid object IDs. Table data contributor role object IDs must be valid GUIDs."
  }
}

variable "tabledatareader_role_object_ids" {
  type        = list(string)
  description = "List of Service Principal or group object IDs to be added with table data reader role on Storage Account."
  default     = []

  validation {
    condition = (
      length([for object_id in var.tabledatareader_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.tabledatareader_role_object_ids)
    )
    error_message = "Invalid object IDs. Table data reader role object IDs must be valid GUIDs."
  }
}

variable "filedatasmbsharecontributor_role_object_ids" {
  type        = list(string)
  description = "List of Service Principal or group object IDs to be added with File Data SMB Share Contributor on Storage Account."
  default     = []

  validation {
    condition = (
      length([for object_id in var.filedatasmbsharecontributor_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.filedatasmbsharecontributor_role_object_ids)
    )
    error_message = "Invalid object IDs. File Data SMB Share Contributor role object IDs must be valid GUIDs."
  }
}

variable "filedatasmbshareelevatedcontributor_role_object_ids" {
  type        = list(string)
  description = "List of Service Principal or group object IDs to be added with File Data SMB Share Elevated Contributor on Storage Account."
  default     = []

  validation {
    condition = (
      length([for object_id in var.filedatasmbshareelevatedcontributor_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.filedatasmbshareelevatedcontributor_role_object_ids)
    )
    error_message = "Invalid object IDs. File Data SMB Share Elevated Contributor role object IDs must be valid GUIDs."
  }
}

variable "filedatasmbsharereader_role_object_ids" {
  type        = list(string)
  description = "List of Service Principal or group object IDs to be added with File Data SMB Share Reader on Storage Account."
  default     = []

  validation {
    condition = (
      length([for object_id in var.filedatasmbsharereader_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.filedatasmbsharereader_role_object_ids)
    )
    error_message = "Invalid object IDs. File Data SMB Share Reader role object IDs must be valid GUIDs."
  }
}

variable "account_tier" {
  type        = string
  description = "The tier to be used for Storage Account. Valid options are Standard and Premium."
  default     = "Standard"
}

variable "account_kind" {
  type        = string
  description = "Defines the Kind of account. Valid options are BlockBlobStorage and StorageV2. Defaults to StorageV2. Important note: if the storage account already exists and the new value does NOT support `access_tier` variable, you must remove the storage account."
  default     = "StorageV2"

  validation {
    condition     = contains(["BlockBlobStorage", "StorageV2"], var.account_kind)
    error_message = "Invalid account kind. Valid options for account_kind are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2."
  }
}

variable "is_hns_enabled" {
  type        = bool
  description = "Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2. This is supported only for Standard account_tier."
  default     = false
}

variable "file_shares" {
  type = list(object({
    name  = string
    quota = number
  }))
  default = []

  description = "The options for the storage file share. File Share can be created only for Standard Tier. This block requires the following inputs: \n  - `name`: The name of the storage file share. The name length should be between 3 and 63 chars. The name can contain only lowercase letters, numbers, and hyphens, and must begin and end with a letter or a number. The name cannot contain two consecutive hyphens.\n  - `quota`: The quota of the storage file share. The quota must be between 1 and 5120 GiB."

  validation {
    condition = (
      length([for share in var.file_shares
        : 1 if
        length(share.name) >= 3
        && length(share.name) <= 63
        && can(regex("^(([a-z0-9]+-?){2,}[a-z0-9]+|[0-9a-z]-[0-9a-z])$", share.name))
      ]) == length(var.file_shares)
    )

    error_message = "Invalid storage file share options. The name length should be between 3 and 63 chars. \n The name can contain only lowercase letters, numbers, and hyphens, and must begin and end with a letter or a number. \n The name cannot contain two consecutive hyphens."
  }

  validation {
    condition = (
      length([for share in var.file_shares : 1 if share.quota >= 1 && share.quota < 5120]) == length(var.file_shares)
    )

    error_message = "Invalid storage file share options. The quota must be between 1 and 5120 GiB."
  }
}

variable "optional_tags" {
  type        = map(string)
  description = "Optional tags for the Azure Storage Account. Please set a value for the key `supportResGroup` when support is not provided by the ownerResGroup team, but by a specialized team (such as IT Systems Operations, IT Network Operations, etc.). This tag should be defined, when required,on each CCoE product template (IaC), and applied automatically during deployment. Typically, a Distribution List to enable sending relevant notifications and information (e.g. in case of incidents, planned maintenances, new available components) from Azure or also the ITSM tool. Tag value will be requested and provided during the workload intake process."
  default     = {}
}

variable "azure_defender_enabled" {
  type        = bool
  description = "Is Azure Defender enabled for this Azure Storage Account?"
  default     = false
}

variable "enable_infrastructure_encryption" {
  type        = bool
  description = "Is infrastructure encryption enabled? Changing this forces a new resource to be created."
  default     = true
}

variable "enable_shared_access_keys" {
  type        = bool
  description = "Does the Storage Account permit requests to be authorized with the account access key via Shared Key? If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD)."
  default     = true
}

variable "customer_managed_keys" {
  type = object({
    cmk_enabled              = bool
    user_managed_identity_id = string
    keyvault_key_id          = string
  })
  description = "Specifies customer managed keys configuration. This block requires the following inputs:\n - `cmk_enabled`: If Customer Managed Key needs to be enabled?\n - `user_managed_identity` Managed Identity that will be assigned to the File Storage. \n - `keyvault_id` Key Vault's id where the key will be stored."
  default = {
    cmk_enabled              = false
    keyvault_key_id          = ""
    user_managed_identity_id = ""
  }
}

variable "immutability_policy" {
  type = object({
    container_name = string
    period_in_days = number
  })
  description = "To configure a time-based retention policy on a container. This block requires the following inputs:\n - `container_name`: Container to configure a time-based retention policy. \n - `period_in_days` You can configure a container-level retention policy for between 1 and 146000 days."
  default     = null
}

variable "legal_hold_policy" {
  type = object({
    container_name = string
    tag            = string
  })
  description = "A legal hold stores immutable data until the legal hold is explicitly cleared. This block requires the following inputs:\n - `container_name`: Container to configure legal hold. \n - `tag` Defines the tag for this lock. Tag name should be 3 to 23 alphanumeric characters."
  default     = null
}

variable "cors_rule" {
  type = object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  })
  description = "Settings related to CORS. This block requires the following inputs:\n - `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request. \n - `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are DELETE, GET, HEAD, MERGE, POST, OPTIONS, PUT or PATCH. \n - `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS. \n - `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients. \n - `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response."
  default     = null

  validation {
    condition = (
      var.cors_rule == null ? true
      : (var.cors_rule != null && !contains([for item in var.cors_rule.allowed_methods : contains(["DELETE", "GET", "HEAD", "MERGE", "POST", "OPTIONS", "PUT", "PATCH"], item)], false))
    )
    error_message = "Invalid cors_rule allowed methods. \n Valid options are DELETE, GET, HEAD, MERGE, POST, OPTIONS, PUT or PATCH."
  }
}

variable "backup_vault" {
  type = object({
    id                 = string
    system_assigned_id = string
  })
  description = "Backup Vault to perform backup related operations on storage account Blobs. This block requires the following inputs:\n - `id`: Backup Vault id. \n - `system_assigned_id`: Principle id of backup vault's system assigned identity. \n Kindly note: this will enable `Operational backup` and `Vaulted Backup` still in public preview."
  default     = null
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Enable public access from specific virtual networks and IP addresses. When the value is `false`, clients can only use the private endpoint to communicate with the storage."
}

variable "enable_blob_anonymous_access" {
  type        = bool
  default     = false
  description = "Allow or disallow nested items within this Account to opt into being public. Anonymous access presents a potential security risk, so if your scenario does not require it, we recommend that you remediate anonymous access for the storage account."
}
