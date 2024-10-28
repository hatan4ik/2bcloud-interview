variable "subnets" {
  description = "Map of subnets with their address prefixes and optional service endpoints"
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string), [])
  }))
}

variable "nsg_ids" {
  description = "Map of subnet names to NSG IDs for association"
  type        = map(string)
  default     = {}
}

variable "route_table_ids" {
  description = "Map of subnet names to Route Table IDs for association"
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "Name of the resource group for the subnets"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "location" {
  description = "Location for the subnets"
  type        = string
}

