#---------------------
#   common variables
#---------------------
variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Valid options are West Europe and East US (case and whitespaces insensitive)."
}

variable "workload_name" {
  type        = string
  description = "Specifies the workload name that will use this resource. This will be used in the resource name."
}

variable "environment" {
  type        = string
  description = "Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development', 'Production' and 'Global'."
}

variable "sequence_number" {
  type        = number
  description = "When using count on the module, you should provide a sequence number that will be the storage account name suffix. It must be an integer."
  default     = 1
}

variable "optional_tags" {
  type        = map(string)
  description = "Optional tags for the AKS resources. Please set a value for the key `supportResGroup` when support is not provided by the ownerResGroup team, but by a specialized team (such as IT Systems Operations, IT Network Operations, etc.). This tag should be defined, when required,on each CCoE product template (IaC), and applied automatically during deployment. Typically, a Distribution List to enable sending relevant notifications and information (e.g. in case of incidents, planned maintenances, new available components) from Azure or also the ITSM tool. Tag value will be requested and provided during the workload intake process."
  default     = {}
}

#--------------------------------
#   Common resources variables
#--------------------------------
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the resource"
}

variable "node_resource_group" {
  type        = string
  description = "The name of the Resource Group where the Kubernetes Nodes should exist. Changing this forces a new resource to be created."
  default     = null
}

#-------------------
# AKS settings
#-------------------
variable "aks_kubernetes_version" {
  type        = string
  description = "Version of Kubernetes specified when creating the AKS managed cluster. If not specified, the latest recommended version will be used at provisioning time (but won't auto-upgrade)."
  default     = null
}

variable "aks_dns_prefix" {
  type        = string
  description = "DNS prefix for the cluster. Will be used as part of the FQDN for the cluster."
}

variable "aks_dns_zone_id" {
  type        = string
  description = "ID of the Private DNS Zone to use for the AKS cluster."
}

variable "managed_identity" {
  # TODO: We pass this through, what should the type be (if any)?
  description = "The managed identity that will be used to run the cluster and kubelets."
}

#----------------------
# AKS network settings
#----------------------
variable "network_plugin" {
  type        = string
  description = "AKS network plugin to use. Allowed values are 'azure' and 'kubenet'. Defaults to 'kubenet'. When 'kubenet' is used the network used for the pods is 172.28.0.0/16 which is aligned with SES IT IP address management."
  default     = "kubenet"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "The network_plugin setting must be either 'azure' or 'kubenet'."
  }
}

variable "network_plugin_mode" {
  type        = string
  default     = null
  description = "AKS network plugin Mode for azure network plugin. Allowed value is 'overlay'."
  validation {
    condition     = var.network_plugin_mode == null || var.network_plugin_mode == "overlay"
    error_message = "The network_plugin mode must be either 'overlay'."
  }
}

variable "ebpf_option" {
  type        = string
  default     = null
  description = "AKS ebpf_data_plane to use. Allowed value is 'cilium'. If null and cilium is preferred to be used, then please set default node pool with subnet id which to be used."
  validation {
    condition     = var.ebpf_option == null || var.ebpf_option == "cilium"
    error_message = "The network_plugin setting must be either 'cilium' or default node pool with pod_subnet_id. Disabling this forces a new resource to be created."
  }
}

#----------------------
# AKS addons settings
#----------------------
variable "key_vault_secrets_provider" {
  description = <<EOT
  Enables and configures the CSI secrets driver for Azure Keyvault.
  - `enabled`: Enables the driver. Defaults to `true`.
  - `secret_rotation_enabled`: Enable rotation of secrets. Defaults to `false`.
  - `secret_rotation_interval`: Sets the secret rotation interval. Only used when `secret_rotation_enabled` is true, the default is `2m`.
  EOT
  type = object({
    enabled                  = bool
    secret_rotation_enabled  = bool
    secret_rotation_interval = string
  })
  default = {
    enabled                  = true
    secret_rotation_enabled  = false
    secret_rotation_interval = "2m"
  }
}

variable "monitor_metric" {
  description = <<EOT
  Prometheus add-on profile for the Kubernetes Cluster. This is required when deploying Managed Prometheus with existing Azure Monitor Workspace.
  - `annotations_allowed`: The list of Kubernetes annotation keys that will be used in the resource's labels metric.
  - `labels_allowed`: A comma separated list of additional kuberenetes label keys that will be used in the resource's labels metric.
  EOT
  type = object({
    annotations_allowed = string
    labels_allowed      = string
  })
  default = null
}

#----------------------
# Default pool settings
#----------------------
variable "default_pool" {
  description = "Settings for the default node pool. WARNING: when modifying the `node_size` you may face side effects that have been documented under the [wiki](https://dev.azure.com/SES-CCoE/SES%20CCoE%20Public/_wiki/wikis/SES-CCoE-Public.wiki/7494/AKS-scale-up-out-down)."
  type = object({
    node_size                    = string
    node_count                   = number
    auto_scaling                 = bool
    availability_zones           = list(string)
    enable_node_public_ip        = optional(bool)
    subnet_id                    = string
    pod_subnet_id                = optional(string)
    fips_enabled                 = optional(bool)
    only_critical_addons_enabled = optional(bool)
  })
}

#-------------------
# Pod settings
#-------------------
variable "linux_admin_username" {
  type        = string
  description = "The admin username for the Cluster. Changing this forces a new resource to be created."
}
variable "ssh_public_key" {
  type        = string
  description = "SSH public key used be the linux admin account to access pods."
}

#-------------------
# Enable Log Diagnostics
#-------------------
variable "log_analytics_workspace_id" {
  type        = string
  description = "The ID of Log Analytics workspace where the OMS Agent logs will be stored."

  validation {
    condition = (
      var.log_analytics_workspace_id == null
      || can(
        regex(
          join("", [
            "^/subscriptions/[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}",
            "/resourcegroups/[[:alnum:]][[:alnum:]-]*[[:alnum:]]",
            "/providers/microsoft.operationalinsights/workspaces/[[:alnum:]][[:alnum:]-]*[[:alnum:]]$"
          ]),
          lower(var.log_analytics_workspace_id)
        )
      )
    )
    error_message = "Invalid log analytics workspace id."
  }
}

#-------------------
# Access settings
#-------------------
# Enable RBAC
#-------------------
variable "cluster_admin_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Cluster Admin role on Azure Kubernetes Service. The service principal object ID for cluster admin role is mandatory."

  validation {
    condition = (
      length([for object_id in var.cluster_admin_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.cluster_admin_role_object_ids) && length(var.cluster_admin_role_object_ids) > 0
    )
    error_message = "Invalid object IDs for Cluster Admin role. Object IDs must be valid GUIDs."
  }
}

variable "cluster_user_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Cluster User role on Azure Kubernetes Service."
  default     = []

  validation {
    condition = (
      length([for object_id in var.cluster_user_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.cluster_user_role_object_ids)
    )
    error_message = "Invalid object IDs for Cluster User role. Object IDs must be valid GUIDs."
  }
}

variable "contributor_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with Contributor role on Azure Kubernetes Service."
  default     = []

  validation {
    condition = (
      length([for object_id in var.contributor_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.contributor_role_object_ids)
    )
    error_message = "Invalid object IDs for Contributor role. Object IDs must be valid GUIDs."
  }
}

variable "rbac_admin_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with RBAC Admin role on Azure Kubernetes Service."
  default     = []

  validation {
    condition = (
      length([for object_id in var.rbac_admin_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.rbac_admin_role_object_ids)
    )
    error_message = "Invalid object IDs for RBAC Admin role. Object IDs must be valid GUIDs."
  }
}

variable "rbac_cluster_admin_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with RBAC Cluster Admin role on Azure Kubernetes Service."
  default     = []

  validation {
    condition = (
      length([for object_id in var.rbac_cluster_admin_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.rbac_cluster_admin_role_object_ids)
    )
    error_message = "Invalid object IDs for RBAC Cluster Admin role. Object IDs must be valid GUIDs."
  }
}

variable "rbac_reader_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with RBAC Reader role on Azure Kubernetes Service."
  default     = []

  validation {
    condition = (
      length([for object_id in var.rbac_reader_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.rbac_reader_role_object_ids)
    )
    error_message = "Invalid object IDs for RBAC Reader role. Object IDs must be valid GUIDs."
  }
}

variable "rbac_writer_role_object_ids" {
  type        = list(string)
  description = "List of object IDs to be added with RBAC Writer role on Azure Kubernetes Service."
  default     = []

  validation {
    condition = (
      length([for object_id in var.rbac_writer_role_object_ids
        : 1 if can(regex("^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", object_id))
      ]) == length(var.rbac_writer_role_object_ids)
    )
    error_message = "Invalid object IDs for RBAC Writer role. Object IDs must be valid GUIDs."
  }
}

variable "http_proxy_config" {
  description = "Proxy settings. WARNING: the settings cannot be updated once the server is created, including the `noproxy` setting. If you need to update this setting, please use the `az` CLI."
  type = object({
    http_proxy  = string
    https_proxy = string
    no_proxy    = list(string)
    trusted_ca  = string
  })
  default = {
    http_proxy  = null
    https_proxy = null
    no_proxy    = null
    trusted_ca  = null
  }
}

variable "sku" {
  type        = string
  default     = "Free"
  description = "The SKU Tier that should be used for this Kubernetes Cluster. Possible values are 'Free', 'Paid' and 'Standard'. Defaults to Free. \n Whilst the AKS API previously supported the 'Paid' SKU - the AKS API introduced a breaking change in API Version 2023-02-01 (used in v3.51.0 and later) where the value Paid must now be set to Standard."

  validation {
    condition     = (var.sku == "Free" || var.sku == "Paid" || var.sku == "Standard")
    error_message = "Invalid sku. Valid options for sku are 'Free', 'Paid' and 'Standard'."
  }
}

variable "load_balancer_sku" {
  type        = string
  default     = "standard"
  description = "Specifies the SKU of the Load Balancer used for this Kubernetes Cluster. Possible values are basic and standard. Defaults to standard. Changing this forces a new resource to be created."

  validation {
    condition     = (var.load_balancer_sku == "standard" || var.load_balancer_sku == "basic")
    error_message = "Invalid loadbalancer sku value. Valid options for sku are 'basic' and 'standard'."
  }
}

variable "outbound_type" {
  type        = string
  default     = "loadBalancer"
  description = "Specifies the outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are loadBalancer, userDefinedRouting. Defaults to loadBalancer."

  validation {
    condition     = (var.outbound_type == "userDefinedRouting" || var.outbound_type == "loadBalancer")
    error_message = "Invalid outbound type. Valid options for outbound type are 'loadBalancer' and 'userDefinedRouting'"
  }
}

variable "network_lb_config" {
  type = object({
    idle_timeout             = optional(number)
    outbound_ip_count        = optional(number)
    outbound_ports_allocated = optional(number)
  })
  description = <<EOT
  Enables and configures the network load balancer configuration.
  - `idle_timeout`: Desired outbound flow idle timeout in minutes for the cluster load balancer. Must be between 4 and 120 inclusive. Defaults to 30.
  - `outbound_ip_count`: Count of desired managed outbound IPs for the cluster load balancer. Must be between 1 and 100 inclusive.
  - `outbound_ports_allocated`: Number of desired SNAT port for each VM in the clusters load balancer. Must be between 0 and 64000 inclusive. Defaults to 0.
  EOT
  default     = {}

  validation {
    condition = (var.network_lb_config.idle_timeout == null ||
    coalesce(var.network_lb_config.idle_timeout, 4) >= 4 || coalesce(var.network_lb_config.idle_timeout, 120) <= 120)
    error_message = "Desired outbound flow idle timeout in minutes must be between 4 and 120"
  }
  validation {
    condition = (var.network_lb_config.outbound_ip_count == null ||
    coalesce(var.network_lb_config.outbound_ip_count, 1) >= 1 || coalesce(var.network_lb_config.outbound_ip_count, 100) <= 100)
    error_message = "Count of desired managed outbound IPs must be between 1 and 100 inclusive."
  }
}

variable "oidc_issuer_enabled" {
  type        = bool
  default     = false
  description = "Enable the OIDC issuer for Azure Kubernetes Service."
}

variable "azure_policy_enabled" {
  type        = bool
  default     = false
  description = "Enable the Azure Policy Add-On."
}

variable "storage_profile" {
  type = object({
    blob_driver_enabled         = bool
    disk_driver_enabled         = bool
    disk_driver_version         = string
    file_driver_enabled         = bool
    snapshot_controller_enabled = bool
  })
  description = <<EOT
  Configure the Azure container storage interface (CSI).
  - `blob_driver_enabled`: Enable the blob driver to mount storage account container in Kubernetes container. Defaults to `false`.
  - `disk_driver_enabled`: Enable the disk driver to mount Azure disk in Kubernetes container. Defaults to `true`.
  - `disk_driver_version`: The version of the disk driver to use. Possible values are `v1` and `v2`. Defaults to `v1`. 
                           The version 2 is in public preview, please review the prerequisites under [this terraform page](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#storage_profile)
  - `file_driver_enabled`: Enable the file driver to mount Azure storage file in Kubernetes container. Defaults to `true`.
  - `snapshot_controller_enabled` : Enable the snapshot controller to manage backup from AKS. Defaults to `true`. Further information is available under [this Microsoft article](snapshot_controller_enabled). 
  EOT
  default = {
    blob_driver_enabled         = false
    disk_driver_enabled         = true
    disk_driver_version         = "v1"
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  validation {
    condition     = (var.storage_profile.disk_driver_version == "v1" || var.storage_profile.disk_driver_version == "v2")
    error_message = "The version of the disk driver to use. Possible values are `v1` and `v2`."
  }
}

variable "enable_audit_logs" {
  type        = bool
  default     = false
  description = "Enable if the audit logs needs to be collected by Microsoft Defender."
}