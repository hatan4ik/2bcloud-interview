variable "environment" {
  type        = string
  description = "The environment where to deploy the resource."

  validation {
    condition     = contains(["Lab", "Test", "Development", "Production", "Global"], var.environment)
    error_message = "Invalid environment. Environment must have one of the following values (case sensitive): [\"Lab\", \"Test\", \"Development\", \"Production\", \"Global\"]."
  }
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location of the resource. Changing this forces a new resource to be created. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive)."

  validation {
    condition     = contains(["westeurope", "eastus", "eastus2", "global", "centralus", "northeurope", "southeastasia", "uksouth", "centralindia"], lower(replace(var.location, " ", "")))
    error_message = "Invalid location. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope, North Europe, southeastasia, South East Asia, uksouth, UK South, centralindia or Central India."
  }
}

variable "sequence_number" {
  type        = number
  description = "When using count on the module, you should provide a sequence number that will be used in the Azure Resource name. It must be an integer between 1 and 999."
  default     = 1

  validation {
    condition     = can(regex("^[[:digit:]]{1,3}$", var.sequence_number)) && var.sequence_number >= 1 && var.sequence_number <= 999
    error_message = "Invalid sequence number. Sequence number must be an integer between 1 and 999."
  }
}

variable "sub_resource_sequence_number" {
  type        = number
  description = "When you have a subresource to create (vm disk, vm extension...), you should provide a sub resource sequence number that will be used in the Azure sub Resource name. It must be an integer between 1 and 99."
  default     = 1

  validation {
    condition     = can(regex("^[[:digit:]]{1,2}$", var.sub_resource_sequence_number)) && var.sub_resource_sequence_number >= 1 && var.sub_resource_sequence_number <= 99
    error_message = "Invalid sub resource sequence number. Sequence number must be an integer between 1 and 99."
  }
}

variable "workload_name" {
  type        = string
  description = "Specifies the workload name that will use this resource. This will be used in the resource name."

  validation {
    condition     = can(regex("^[a-z0-9]{1,9}$+", var.workload_name))
    error_message = "Invalid workload name. Workload name should be an alphanumeric lower case string limited up to 9 characters."
  }
}

variable "subscription_name" {
  description = "Used for Resource Health and Service Health Alerts."
  default     = ""
}

variable "suffix" {
  description = "Free text used for some resources which supports suffix : subscription, subnet, network_security_group, service|resource health alerts, action groups. The value will be truncated according to the naming convention."
  default     = ""
}

variable "private_endpoint_subnet_name" {
  description = "The name of the subnet of the private endpoint."
  default     = ""
}

variable "private_endpoint_resource_name" {
  description = "The name of the Azure resource involved in private endpoint."
  default     = ""
}
