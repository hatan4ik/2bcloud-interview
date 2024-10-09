variable "environment" {
  type        = string
  description = "Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development' and 'Production'."
}

variable "workload_name" {
  type        = string
  description = "Specifies the workload name that will use this resource. This will be used in the resource name."
}

variable "sequence_number" {
  type        = number
  default     = 1
  description = "When using count on the module, you should provide a sequence number that will be the Linux VM name suffix. It must be an integer."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group to deploy the VM."
}

variable "recovery_service_vault" {
  type = object({
    resource_group_name = string
    name                = string
  })
  description = "The recovery options for the recovery service vault for the backup. If not null, this block requires the following inputs: \n  - `name`: The name of the service vault \n  - `resource_group_name`: The name of the resource group containing the service vault"
  default     = null
}

variable "distribution" {
  type        = string
  description = "The linux distribution used on this machine. Allowed values are `CentOS7`, `CentOS8`, `Debian9`, `Debian10`, `Debian11`, `Ubuntu1804`, `Ubuntu2004` and `Ubuntu2204`."
  default     = "CentOS7"
  validation {
    condition     = contains(["CentOS7", "CentOS8", "CentOS8-LVM", "CentOS7-LVM", "Debian9", "Debian10", "Debian11", "Ubuntu1804", "Ubuntu2004", "Ubuntu2204", "RedHat8"], var.distribution)
    error_message = "Invalid distribution. Allowed values are `CentOS7`, `CentOS8-LVM`, `CentOS7-LVM`, `CentOS8`, `Debian9`, `Debian10`, `Debian11`, `RedHat8`, `Ubuntu1804`, `Ubuntu2004` and `Ubuntu2204`."
  }
}

variable "size" {
  type        = string
  description = "The size of this machine. Allowed values are like `Standard_D2s_v3`, `Standard_D4s_v3`, `Standard_D8s_v3` etc. Find out more on the valid VM sizes in each region at https://aka.ms/azure-regionservices."
  default     = "Standard_D2s_v3"
  validation {
    condition = (
      length(var.size) > 9
      && substr(var.size, 0, 9) == "Standard_"
    )
    error_message = "Invalid size. Allowed values are like `Standard_D2s_v3`, `Standard_D4s_v3`, `Standard_D8s_v3` etc. Find out more on the valid VM sizes in each region at https://aka.ms/azure-regionservices."
  }
}

variable "azure_availability_zone" {
  type        = number
  default     = null
  description = "Set virtual machine availability zones number. Allowed value is a 1, 2 or 3."

  validation {
    condition = (
      var.azure_availability_zone == null
      || can(regex("^[123]?$", var.azure_availability_zone))
    )
    error_message = "Invalid virtual machine availability zone number. Allowed value are a 1, 2 or 3."
  }
}

variable "optional_tags" {
  type        = map(string)
  default     = {}
  description = "Optional tags for the Linux Virtual Machine. For more details, please check the Optional tags and values in the [Tagging convention wiki page](https://dev.azure.com/SES-CCoE/CCoE/_wiki/wikis/SES%20CCoE%20Wiki/862/Tagging-Convention?anchor=optional-tags-and-values)."
}

variable "tag_OSUpdateDayOfWeekend" {
  type        = string
  default     = "Saturday"
  description = "The day in which update will be planned. Allowed values are `Saturday` and `Sunday`."

  validation {
    condition     = contains(["Sunday", "Saturday"], var.tag_OSUpdateDayOfWeekend)
    error_message = "Invalid tag value. Allowed values are `Saturday` and `Sunday`."
  }
}

variable "tag_OSUpdateSkip" {
  type        = bool
  default     = false
  description = "This tag's value must be set if you want or not to skip the VM's update. If `true`, next update circle the VM will be skipped from the deployment query or not."
}

variable "tag_OSUpdateDisabled" {
  type        = bool
  default     = false
  description = "This tag's value must be set if you want or not to disable the VM's regular update."
}

variable "tag_OSUpdateException" {
  type        = bool
  default     = false
  description = "This tag's value must be set if the VM is `excluded`q from default Deployment Groups."
}

variable "backup_policy_name" {
  type        = string
  default     = "DefaultPolicy"
  description = "The options to set the name of the existing backup policy in place in the Recovery Service Vault for the virtual machine. If no value is provided value will be set to `DefaultPolicy`."
}

variable "private_ip_address" {
  type        = string
  description = "The Static IP Address which should be used (IP allocation will be dynamic if not set)."
  default     = null
}

variable "subnet_id" {
  type        = string
  description = "The subnet ID where the VM will be deployed."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive)."
}

variable "credentials" {
  type = object({
    user_secret_name     = string
    password_secret_name = optional(string)
    ssh_public_key       = optional(string)
    disable_password     = bool
  })
  description = <<-EOT
   The names used for VMs secrets inside Key Vault. This block requires the following inputs:
   - `user_secret_name`: The user name secret.
   Either:
   - `password_secret_name`: The password secret.
   or:
   - `ssh_public_key`: The SSH key to allow. Only ssh-rsa keys are accepted.
   Is the password used or not. In case ssh_public_key is used, this should be set to 'true'.
   - `disable_password`: True or false.
   EOT
  validation {
    condition = (
      (var.credentials.password_secret_name != null && var.credentials.ssh_public_key == null) ||
      (var.credentials.password_secret_name == null && var.credentials.ssh_public_key != null)
    )
    error_message = "Either `password_secret_name` or `ssh_public_key` must be provided, not both."
  }
}

variable "disk_encryption_set_id" {
  type        = string
  description = "The disk encryption set id that will be used for Server Side Encryption of Linux VM."
}

variable "storage_account_uri" {
  type        = string
  description = "The uri for the storage account used to store boot diagnostics."
}

# RBAC implementation
variable "classic_contributor_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Classic Virtual Machine Contributor role on Linux VM."
  default     = []

  validation {
    condition = (
      length([for object_id in var.classic_contributor_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.classic_contributor_role_object_ids)
    )
    error_message = "Invalid object IDs for Classic Virtual Machine Contributor role. Object IDs must be valid GUIDs."
  }
}

variable "administrator_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Virtual Machine Administrator role on Linux VM."
  default     = []

  validation {
    condition = (
      length([for object_id in var.administrator_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.administrator_role_object_ids)
    )
    error_message = "Invalid object IDs for Virtual Machine Administrator role. Object IDs must be valid GUIDs."
  }
}

variable "contributor_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Virtual Machine Contributor role on Linux VM."
  default     = []

  validation {
    condition = (
      length([for object_id in var.contributor_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.contributor_role_object_ids)
    )
    error_message = "Invalid object IDs for Virtual Machine Contributor role. Object IDs must be valid GUIDs."
  }
}

variable "user_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Virtual Machine User Login role on Linux VM."
  default     = []

  validation {
    condition = (
      length([for object_id in var.user_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.user_role_object_ids)
    )
    error_message = "Invalid object IDs for Virtual Machine User Login role. Object IDs must be valid GUIDs."
  }
}

variable "data_disk_config" {
  type = map(object({
    size                 = number
    storage_account_type = string
  }))
  description = "Specifies the size of the data disks to create in gigabytes. eg. {disk1 = 50, disk2 = 100}"
  default     = {}

  validation {
    condition = alltrue([
    for o in var.data_disk_config : (o.size >= 50 && o.size <= 4095)])
    error_message = "Invalid data disk config.  - \n `size` must be an integer between 50 and 4095."
  }
  validation {
    condition = alltrue([
    for o in var.data_disk_config : (contains(["Standard_LRS", "StandardSSD_ZRS", "Premium_LRS", "Premium_ZRS", "StandardSSD_LRS"], o.storage_account_type))])
    error_message = "Invalid data disk config.  - \n The type of storage to use for the managed disk. Possible values are 'Standard_LRS', 'StandardSSD_ZRS', 'Premium_LRS', 'Premium_ZRS', 'StandardSSD_LRS'."
  }
}

variable "custom_data" {
  type        = string
  description = "Custom Data which should be used for this Virtual Machine as cloud-init."
  default     = null
  sensitive   = true
}

variable "user_assigned_ids" {
  type        = list(string)
  description = "List of User Assigned Managed Identity IDs to be assigned to this Linux Virtual Machine. \n Kindly note that module will add the System Assigned Identities by default."
  default     = null
}

variable "os_disk_caching" {
  type        = string
  description = "The Type of Caching which should be used for the Internal OS Disk. Possible values are 'None', 'ReadOnly' and 'ReadWrite'."
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  type        = string
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values are 'Standard_LRS', 'StandardSSD_LRS', 'Premium_LRS', 'StandardSSD_ZRS' and 'Premium_ZRS'. Changing this forces a new resource to be created."
  default     = null
  validation {
    condition     = var.os_disk_storage_account_type == null ? true : contains(["Standard_LRS", "StandardSSD_ZRS", "Premium_LRS", "Premium_ZRS", "StandardSSD_LRS"], var.os_disk_storage_account_type)
    error_message = "Invalid OS disk storage account type.  - \n The type of storage to use for the managed disk. Possible values are 'Standard_LRS', 'StandardSSD_ZRS', 'Premium_LRS', 'Premium_ZRS', 'StandardSSD_LRS'."
  }
}

variable "availability_set_id" {
  type        = string
  default     = null
  description = "Specifies the ID of the Availability Set in which the Virtual Machine should exist. This input having conflict with availability_zones and changing this forces a new resource to be created."
}

variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "Source image for the Linux VM. This block requires the following inputs:\n  - `publisher`: The the publisher of the image used to create the virtual machine.\n  - `offer`: The offer of the image used to create the virtual machine. \n  - `sku`: The SKU of the image used to create the virtual machine. \n  - `version`: The version of the image used to create the virtual machine. Changing this forces a new resource to be created."
  default     = null
}

variable "source_image_id" {
  description = "The ID of an Image which each Virtual Machine in this Linux VM should be based on."
  type        = string
  default     = null
}

variable "capacity_reservation_group_id" {
  type        = string
  default     = null
  description = "Specifies the ID of the Capacity Reservation Group which the Virtual Machine should be allocated to."
}

variable "priority" {
  type        = string
  default     = null
  description = "Specifies the priority of this Virtual Machine. Possible values are `Regular` and `Spot`."

  validation {
    condition     = var.priority != null ? contains(["Regular", "Spot"], var.priority) : true
    error_message = "Possible priority values are `Regular` and `Spot`."
  }
}

variable "eviction_policy" {
  type        = string
  default     = null
  description = "Specifies what should happen when the Virtual Machine is evicted for price reasons when using a Spot instance. Possible values are `Deallocate` and `Delete`."
}

variable "encryption_at_host_enabled" {
  type        = bool
  description = "Should all of the disks (including the temp disk) attached to this Virtual Machine be encrypted by enabling Encryption at Host?"
  default     = false
}

variable "bypass_platform_safety_checks_on_user_schedule_enabled" {
  type        = bool
  description = "Specifies whether to skip platform scheduled patching when a user schedule is associated with the VM.\n This value can be set `true` only when `path_mode` is set to `AutomaticByplatform`. \n Please check the supported list from this link. https://aka.ms/VMGuestPatchingCompatibility. \n Default value is `false`."
  default     = false
}

variable "patch_assessment_mode" {
  type        = string
  description = "Specifies the mode of VM Guest Patching for the Virtual Machine. Possible values are `AutomaticByPlatform` or `ImageDefault`. Defaults to `ImageDefault`."
  default     = "ImageDefault"

  validation {
    condition     = contains(["AutomaticByPlatform", "ImageDefault"], var.patch_assessment_mode)
    error_message = "Invalid value. Allowed values are `AutomaticByPlatform` and `ImageDefault`."
  }
}

variable "patch_mode" {
  type        = string
  description = "Specifies the mode of in-guest patching to this Linux Virtual Machine.\n Possible values are `AutomaticByPlatform` and `ImageDefault`. Defaults to `ImageDefault`."
  default     = "ImageDefault"

  validation {
    condition     = contains(["AutomaticByPlatform", "ImageDefault"], var.patch_mode)
    error_message = "Invalid value. Allowed values are `AutomaticByPlatform` and `ImageDefault`."
  }
}