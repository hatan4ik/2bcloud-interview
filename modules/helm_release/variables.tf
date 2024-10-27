# Variables for Helm Release Module
variable "name" {
  type        = string
  description = "The name of the Helm release."
}

variable "chart" {
  type        = string
  description = "The Helm chart to deploy."
}

variable "repository" {
  type        = string
  description = "The repository URL for the Helm chart."
}

variable "version" {
  type        = string
  description = "The version of the Helm chart."
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace in which to deploy the release."
}

variable "set_values" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "List of name/value pairs to set in the Helm chart."
}
