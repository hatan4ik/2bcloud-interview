variable "subnets" {
  type = map(object({
    address_prefix = string
  }))
  description = "A map of subnet names to their address prefixes."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the VNet."
}

variable "vnet_name" {
  type        = string
  description = "The name of the Virtual Network."
}

variable "nsg_ids" {
  type        = map(string)
  description = "A map of subnet names to NSG IDs to associate with each subnet."
  default     = {}
}

variable "route_table_id" {
  type        = string
  description = "The ID of the route table to associate with each subnet."
  default     = null
}

variable "location" {
  type        = string
  description = "The location for the resources in this module."
}
