variable "workload_name" {
  type        = string
  description = "Specifies the workload name that will use this resource. This will be used in the resource name."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group to deploy the Azure Container Registry."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
}

variable "environment" {
  type        = string
  description = "Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development' and 'Production'."
}

variable "georeplication_locations" {
  type        = list(string)
  description = "Specifies the supported Azure location for geo replication. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive)."
  default     = null
}

variable "sequence_number" {
  type        = number
  description = "When using count on the module, you should provide a sequence number that will be the Azure Container Registry name suffix. It must be an integer."
  default     = 1
}

variable "image_pull_service_principal_ids" {
  type        = list(string)
  description = "List of Service Principal object IDs to be added with AcrPull role on Azure Container Registry."
  default     = []

  validation {
    condition = (
      length([for principal_id in var.image_pull_service_principal_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", principal_id))
      ]) == length(var.image_pull_service_principal_ids)
    )

    error_message = "Invalid image pull principals IDs. Principal IDs must be valid GUIDs."
  }
}

variable "image_push_service_principal_ids" {
  type        = list(string)
  description = "List of Service Principal object IDs to be added with AcrPush role on Azure Container Registry."
  default     = []

  validation {
    condition = (
      length([for principal_id in var.image_push_service_principal_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", principal_id))
      ]) == length(var.image_push_service_principal_ids)
    )

    error_message = "Invalid image push principals IDs. Principal IDs must be valid GUIDs."
  }
}

variable "optional_tags" {
  type        = map(string)
  description = "Optional tags for the Azure Container Registry. This block requires the following inputs:\n  - `supportResGroup`: The SupportResGroup is to be used when support is not provided by the ownerResGroup team, but by a specialized team (such as IT Systems Operations, IT Network Operations, etc.). This tag should be defined, when required,on each CCoE product template (IaC), and applied automatically during deployment. Typically, a Distribution List to enable sending relevant notifications and information (e.g. in case of incidents, planned maintenances, new available components) from Azure or also the ITSM tool. Tag _ value to be requested and provided during the workload intake process."
  default     = {}
}

variable "private_endpoint" {
  type = map(object({
    subnet_id = string
    ip_configuration = optional(list(object({
      member_name        = string
      private_ip_address = string
    })))
  }))
  description = "Specifies the private endpoint details for ACR. This block requires the following inputs:\n  - `subnet_id`: The subnet ID to use for the private endpoint of the ACR. \n - `ip_configuration`: This block is optional and contains the following inputs:\n -`private_ip_address`: The static IP addres for the ACR private endpoint.\n - `member_name`: The member name this IP applies to."
  default     = {}
}

variable "customer_managed_keys" {
  type = object({
    cmk_enabled                    = bool
    user_managed_identity_id       = string
    user_managed_identity_clientid = string
    keyvault_id                    = string
    kvt_key_id                     = string
  })
  description = "Specifies customer managed keys configuration. This block requires the following inputs:\n - `cmk_enabled`: If Customer Managed Key needs to be enabled?\n - `user_managed_identity_id` Managed Identity ID that will be assigned to the ACR. \n - `user_managed_identity_clientid` Managed Identity Client ID that will be assigned to the ACR. \n - `keyvault_id` Key Vault's id where the key will be stored.  \n - `kvt_key_id` KeyVault's Key id to be used for encryption."
  default = {
    cmk_enabled                    = false
    user_managed_identity_id       = ""
    user_managed_identity_clientid = ""
    keyvault_id                    = ""
    kvt_key_id                     = ""
  }
}
