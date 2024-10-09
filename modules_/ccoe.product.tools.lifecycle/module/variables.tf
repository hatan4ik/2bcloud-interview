variable "resource_id" {
  type        = string
  description = "The ID of the resource being created/destroyed."
}

variable "workload_name" {
  type        = string
  description = "The workload name."
}

variable "environment" {
  type        = string
  description = "The environment in which the apply/destroy is happening."
}
