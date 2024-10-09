variable "resource_group_name" {
  type        = string
  description = "The resource group where to deploy the Key Vault."
}

variable "workload_name" {
  type        = string
  description = "Specifies the workload name that will use this resource. This will be used in the resource name."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. alid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive)."
}

variable "environment" {
  type        = string
  description = "Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development', 'Production' and 'Global'."
}

variable "private_endpoint" {
  type = map(object({
    subnet_id          = string
    private_ip_address = optional(string)
  }))
  description = "This block requires following inputs:\n -`subnet_id (required)`: The ID of the Subnet within which the KeyVault should be deployed. \n private_ip_address (Optional): Private IP Address assign to the Private Endpoint. The last one and first four IPs in any range are reserved and cannot be manually assigned."
  default     = {}
}

variable "enabled_for_vm_deployment" {
  type        = bool
  description = "Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the Key Vault."
  default     = false
}

variable "enabled_for_disk_encryption" {
  type        = bool
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys."
  default     = false
}

variable "enabled_for_template_deployment" {
  type        = bool
  description = "Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the Key Vault."
  default     = false
}

variable "enabled_for_sql_deployment" {
  type        = bool
  description = "Boolean flag to specify whether Azure SQL is permitted to retrieve keys from the Key Vault."
  default     = false
}

variable "sequence_number" {
  type        = number
  description = "Sequence number to be defined according to naming convention."
  default     = 1
}

variable "authorized_vnet_subnet_ids" {
  type        = list(string)
  description = "IDs of the virtual network subnets authorized to connect to the Key Vault."
  default     = []
}

variable "authorized_ips_or_cidr_blocks" {
  type        = list(string)
  description = "One or more IP Addresses, or CIDR Blocks which should be able to access the Key Vault."
  default     = []
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Is Purge Protection enabled for this Key Vault?"
  default     = false
}

variable "soft_delete_retention_days" {
  type        = number
  description = "The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. By default, Key Vault will set this value to 7."
  default     = 7

  validation {
    condition     = can(regex("^[[:digit:]]{1,2}$", var.soft_delete_retention_days)) && var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Invalid number of days for soft delete."
  }
}

variable "admin_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with admin role on Key Vault. The service principal object ID for admin role is mandatory."

  validation {
    condition = (
      length([for object_id in var.admin_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.admin_role_object_ids) && length(var.admin_role_object_ids) > 0
    )
    error_message = "Invalid object IDs for Admin role. Object IDs must be valid GUIDs."
  }
}

variable "reader_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with reader role on Key Vault."
  default     = []

  validation {
    condition = (
      length([for object_id in var.reader_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.reader_role_object_ids)
    )
    error_message = "Invalid object IDs for Reader role. Object IDs must be valid GUIDs."
  }
}

variable "certificates_officer_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Key Vault Certificates Officer role on Key Vault."
  default     = []

  validation {
    condition = (
      length([for object_id in var.certificates_officer_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.certificates_officer_role_object_ids)
    )
    error_message = "Invalid object IDs for Certificates Officer role. Object IDs must be valid GUIDs."
  }
}

variable "secrets_user_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Key Vault Secrets User role on Key Vault."
  default     = []

  validation {
    condition = (
      length([for object_id in var.secrets_user_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.secrets_user_role_object_ids)
    )
    error_message = "Invalid object IDs for Secrets User role. Object IDs must be valid GUIDs."
  }
}

variable "crypto_user_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Key Vault Crypto User role on Key Vault."
  default     = []

  validation {
    condition = (
      length([for object_id in var.crypto_user_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.crypto_user_role_object_ids)
    )
    error_message = "Invalid object IDs for Crypto User role. Object IDs must be valid GUIDs."
  }
}

variable "crypto_officer_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Key Vault Crypto Officer role on Key Vault."
  default     = []

  validation {
    condition = (
      length([for object_id in var.crypto_officer_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.crypto_officer_role_object_ids)
    )
    error_message = "Invalid object IDs for Crypto Officer role. Object IDs must be valid GUIDs."
  }
}

variable "crypto_encryption_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Key Vault Crypto Service Encryption User role on Key Vault."
  default     = []

  validation {
    condition = (
      length([for object_id in var.crypto_encryption_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.crypto_encryption_role_object_ids)
    )
    error_message = "Invalid object IDs for Crypto Service Encryption role. Object IDs must be valid GUIDs."
  }
}

variable "secrets_officer_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Key Vault Secrets Officer role on Key Vault."
  default     = []

  validation {
    condition = (
      length([for object_id in var.secrets_officer_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.secrets_officer_role_object_ids)
    )
    error_message = "Invalid object IDs for Secrets Officer role. Object IDs must be valid GUIDs."
  }
}

variable "optional_tags" {
  type        = map(string)
  description = "Optional tags for the Azure Key Vault. Please set a value for the key `supportResGroup` when support is not provided by the ownerResGroup team, but by a specialized team (such as IT Systems Operations, IT Network Operations, etc.). This tag should be defined, when required,on each CCoE product template (IaC), and applied automatically during deployment. Typically, a Distribution List to enable sending relevant notifications and information (e.g. in case of incidents, planned maintenances, new available components) from Azure or also the ITSM tool. Tag value will be requested and provided during the workload intake process."
  default     = {}
}

#Added for gateway Deployment
variable "enabled_for_agw_deployment" {
  type        = bool
  description = "Boolean flag to specify whether Azure Application Gateway are permitted to retrieve certificates stored as secrets from the Key Vault."
  default     = false
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Enable public access from specific virtual networks and IP addresses. When the value is `false`, clients can only use the private endpoint to communicate with the storage."
}