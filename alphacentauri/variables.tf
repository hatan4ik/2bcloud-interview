variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    name              = string
    address_prefix    = string
    service_endpoints = optional(list(string))
  }))
}

variable "nsgs" {
  description = "Map of network security group configurations"
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


# Variables
variable "namespace" {
  default = "myapp"
}

variable "nginx_ingress_image" {
  default = ""
}

variable "myapp_image" {
  default = ""
}

variable "replicas" {
  type        = number
  default     = 1
  description = "Number of replicas for the deployment"

  validation {
    condition     = var.replicas > 0
    error_message = "Replica count must be greater than 0."
  }
}


variable "resource_prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "myapp"
}

variable "common_labels" {
  type        = map(string)
  description = "Common labels to be applied to all resources"
  default     = {}
}

variable "ingress_replicas" {
  type        = number
  description = "Number of replicas for the NGINX ingress controller"
  default     = 1
}


variable "ingress_cpu_limit" {
  type        = string
  description = "CPU limit for the NGINX ingress controller"
  default     = "200m"
}

variable "ingress_memory_limit" {
  type        = string
  description = "Memory limit for the NGINX ingress controller"
  default     = "256Mi"
}

variable "ingress_cpu_request" {
  type        = string
  description = "CPU request for the NGINX ingress controller"
  default     = "100m"
}

variable "ingress_memory_request" {
  type        = string
  description = "Memory request for the NGINX ingress controller"
  default     = "128Mi"
}

variable "target_namespaces" {
  type        = list(string)
  description = "List of namespaces to create secrets in. Defaults to all namespaces if not specified."
  default     = []
}

variable "app_namespace" {
  type        = string
  description = "Kubernetes namespace for the application"
  default     = "myapp"
}

variable "kubernetes_version" {
  type        = string
  description = "AKS version"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the cluster"
  default     = 1
}

variable "vm_size" {
  type        = string
  description = "VM size for the nodes"
  default     = ""
}


#####################################
#### Bellow is part of Modules folder
variable "location" {
  description = "Location of the resource group"
  type        = string
}