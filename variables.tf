variable "resource_group_name" {
  description = "The name of the resource group to deploy to"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix to use for Azure resources"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "" # Example, adjust as needed
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "VM size for the AKS nodes"
  type        = string
  default     = "Standard_D2_v2" # Example, choose an appropriate size
}

variable "replicas" {
  description = "Number of replicas for the 'myapp' deployment"
  type        = number
  default     = 1
}

variable "app_namespace" {
  description = "Kubernetes namespace for the 'myapp' application"
  type        = string
  default     = ""
}

variable "target_namespaces" {
  description = "List of namespaces to create the ACR pull secret in"
  type        = list(string)
  default     = [] # Empty by default, meaning only 'default' namespace
}

# Subnets Configuration
variable "subnets" {
  description = "Configuration for subnets"
  type = map(object({
    name           = string
    address_prefix = string
    service_endpoints = list(string)
  }))
}

# Network Security Groups Configuration
variable "nsgs" {
  description = "Configuration for Network Security Groups"
  type = map(object({
    name = string
    rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))
}
variable "route_table_ids" {
  description = "Map of subnet names to Route Table IDs for association"
  type        = map(string)
  default     = {}
}

variable "nsg_ids" {
  description = "Map of subnet names to NSG IDs for association"
  type        = map(string)
  default     = {}  # Optional: default to an empty map if not all subnets have NSGs
}

variable "subscription_id" {
  description = "Subscription ID"
  type        = string
}