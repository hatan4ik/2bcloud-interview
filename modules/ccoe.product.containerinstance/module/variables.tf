variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive)."
}

variable "environment" {
  type        = string
  description = "Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development' and 'Production'."
}

variable "workload_name" {
  type        = string
  description = "Specifies the workload name that will use this resource. This will be used in the resource name."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where to deploy the Azure Container Instance."
}

variable "registry" {
  type = object({
    name                         = string
    resource_group_name          = string
    username_secret_name         = string
    password_secret_name         = string
    keyvault_name                = string
    keyvault_resource_group_name = string
  })
  description = "The Azure Container Registry from where to pull the image(s). This block requires the following inputs:\n  - `name`: The name of the Azure Container Registry.\n  - `resource_group_name`: The Azure Container Registry resource group name.\n  - `username_secret_name`: The username secret name stored in Key Vault to use for Azure Container Registry authentication.\n  - `password_secret_name`: The password secret name stored in Key Vault to use for Azure Container Registry authentication.\n  - `keyvault_name`: Name of the Key Vault containing the credentials secrets.\n  - `keyvault_resource_group_name`: Name of the resource group containing the Key Vault."
}

variable "containers" {
  type = list(object({
    name       = string
    image_name = string
    tag        = string
    cpu        = number
    memory     = number
    ports = list(object({
      port     = number
      protocol = string
    }))
    volume = object({
      name                 = string
      mount_path           = string
      share_name           = string
      storage_account_key  = string
      storage_account_name = string
    })
  }))
  description = "The containers to run on the Azure Container Instance. This block requires the following inputs:\n  - `name`: The name of the container.\n  - `image_name`: The name of the Docker Image in the registry.\n  - `tag`: The tag of the image to use to run the container.\n  - `cpu`: The amount of CPU to provide to the container.\n  - `memory`: The amount of Memory in GB to provide to the container.\n  - `ports`: The list of ports to bind to the container.  This block requires the following inputs:\n    - `port`: The port number.\n    - `protocol`: The protocol associated with the binded port.\n  - `volume`: The volume to mount to the container.  This block requires the following inputs:\n  - `mount_path`: The path where to mount the volume.\n  - `name`: The volume name.\n  - `share_name`: The Azure Storage Account file share name to use.\n  - `storage_account_name`: The name of the storage account where the file share exists.\n  - `storage_account_key`: The storage account access key."

  validation {
    condition = (
      length(var.containers) > 0 &&
      length([for container in var.containers : 1 if
        container.cpu >= 1 && container.cpu <= 4
        && container.memory >= 0.5 && container.memory <= 16
        && length([for port in container.ports : 1 if
          contains(["UDP", "TCP"], upper(port.protocol))
          && port.port >= 0 && port.port <= 65535
        ]) == length(container.ports)
      ]) == length(var.containers)
    )
    error_message = "Invalid container list. CPU must be in [1,4] and Memory must be in [0.5, 16]. Port must be between 0 and 65535. Protocol must be either `TCP` or `UDP`."
  }

  validation {
    condition = (
      length([for container in var.containers : 1 if
        container.volume == null ||
        can(regex(":", try(container.volume.mount_path, ""))) == false
        && can(regex("^/", try(container.volume.mount_path, "/")))
      ]) == length(var.containers)
    )
    error_message = "Invalid mount path. Mount path must start with a slash and can't contain column (':')."
  }
}

variable "restart_policy" {
  type        = string
  description = "The containers restart policy. Can be either `Always`, `Never`, or `OnFailure`."
  default     = "Always"

  validation {
    condition     = var.restart_policy == null || can(regex("Never|Always|OnFailure", var.restart_policy))
    error_message = "Invalid restart policy. Restart Policy can be either `Always`, `Never`, or `OnFailure`."
  }
}

variable "sequence_number" {
  type        = number
  description = "When using count on the module, you should provide a sequence number that will be the storage account name suffix. It must be an integer."
  default     = 1
}

variable "subnet_ids" {
  type        = list(string)
  description = "The subnet resource IDs for a container group. Changing this forces a new resource to be created."
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Map of non-sensitive environment variables to set on the Azure Container Instance."
}

variable "secure_environment_variables" {
  type        = map(string)
  default     = {}
  description = "Map of sensitive environment variables to set on the Azure Container Instance."
}
variable "optional_tags" {
  type        = map(string)
  description = "Optional tags for the Azure Container Instances. Please set a value for the key `supportResGroup` when support is not provided by the ownerResGroup team, but by a specialized team (such as IT Systems Operations, IT Network Operations, etc.). This tag should be defined, when required,on each CCoE product template (IaC), and applied automatically during deployment. Typically, a Distribution List to enable sending relevant notifications and information (e.g. in case of incidents, planned maintenances, new available components) from Azure or also the ITSM tool. Tag value will be requested and provided during the workload intake process."
  default     = {}
}

