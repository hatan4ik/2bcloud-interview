variable "nsgs" {
  description = "Map of Network Security Groups (NSGs)"
  type        = map(any)
}

variable "subnets" {
  description = "Map of subnets"
  type        = map(object({
    name = string
  }))
}


variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}
