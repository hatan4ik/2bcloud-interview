variable "name" {
  type        = string
  description = "The name of the Helm release."
}

variable "chart" {
  type        = string
  description = "The name of the Helm chart to deploy."
}

variable "repository" {
  type        = string
  description = "The Helm repository URL for the chart."
}

variable "chart_version" {
  type        = string
  description = "The chart version to deploy."
  default     = null
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace in which to install the chart."
}

variable "set_values" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "List of values to set for the Helm chart."
  default     = []
}
variable "create_namespace" {
  description = "Create the namespace if it does not yet exist"
  type        = bool
  default     = false
}
variable "timeout" {
  description = "Time in seconds to wait for any individual Kubernetes operation (like Jobs for hooks) (default 300)"
  type        = number
  default     = 300
}