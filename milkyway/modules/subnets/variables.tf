variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    name               = string
    address_prefix     = string
    service_endpoints  = optional(list(string))
  }))
}
