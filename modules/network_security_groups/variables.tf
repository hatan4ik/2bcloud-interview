variable "nsgs" {
  description = "Map of Network Security Groups (NSGs) with optional rules"
  type        = map(object({
    rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the NSGs."
}

variable "location" {
  type        = string
  description = "The location for the NSGs in this module."
}
variable "subnets" {
  type        = map(any)
  description = "Map of subnets for use within NSG module if needed."
}
