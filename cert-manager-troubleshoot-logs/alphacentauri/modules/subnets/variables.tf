variable "subnets" {
  description = "List of subnets with details like name and address_prefix"
  type        = map(object({
    name           = string
    address_prefix = string
  }))
}

variable "nsg_ids" {
  description = "Map of NSG IDs to associate with each subnet"
  type        = map(string)
}

# variable "route_table_id" {
#   description = "Route table ID to associate with subnets"
#   type        = string
# }

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "vnet_address_prefix" {
  default     = "10.0.0.0/16"
  description = "Virtual network address prefix"
  type        = string
}