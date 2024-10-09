/**
 * # Azure Kubernetes Service
 *
 * This product will deploy an AKS cluster following SES standards.
 *
 */

resource "azurerm_kubernetes_cluster" "aks" {

  # Basic configuration
  name                    = module.k8s_name.kubernetes_service
  location                = var.location
  resource_group_name     = var.resource_group_name
  node_resource_group     = var.node_resource_group
  kubernetes_version      = var.aks_kubernetes_version
  private_cluster_enabled = true
  local_account_disabled  = true # local accounts will be disabled
  sku_tier                = var.sku
  oidc_issuer_enabled     = var.oidc_issuer_enabled
  azure_policy_enabled    = var.azure_policy_enabled
  tags                    = local.tags


  # Cluster identities
  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity.id]
  }

  # Access control
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  # DNS settings
  private_dns_zone_id        = var.aks_dns_zone_id
  dns_prefix_private_cluster = var.aks_dns_prefix

  # Networking
  network_profile {
    network_plugin = var.network_plugin

    // Hardcoded IPs are assigned for this purpose in SES IPAM.
    dns_service_ip = "172.21.0.10"
    service_cidr   = "172.21.0.0/22"
    pod_cidr       = local.pod_cidr

    ebpf_data_plane     = var.ebpf_option != null ? var.ebpf_option : null
    network_plugin_mode = var.network_plugin_mode != null ? var.network_plugin_mode : null

    load_balancer_sku = var.load_balancer_sku
    outbound_type     = var.outbound_type

    dynamic "load_balancer_profile" {
      for_each = var.network_lb_config != null && var.load_balancer_sku == "standard" && var.outbound_type == "loadBalancer" ? [1] : []
      content {
        idle_timeout_in_minutes   = var.network_lb_config.idle_timeout
        managed_outbound_ip_count = var.network_lb_config.outbound_ip_count
        outbound_ports_allocated  = var.network_lb_config.outbound_ports_allocated
      }
    }
  }

  # Default node pool
  default_node_pool {
    name                        = "default"
    temporary_name_for_rotation = "defaulttmp"

    enable_node_public_ip = lookup(var.default_pool, "enable_node_public_ip", null) != null ? var.default_pool.enable_node_public_ip : false
    # node_public_ip_enabled      = false   ## From azurerm 4.0.0

    vm_size                      = var.default_pool.node_size
    node_count                   = var.default_pool.node_count
    vnet_subnet_id               = var.default_pool.subnet_id
    pod_subnet_id                = lookup(var.default_pool, "pod_subnet_id", null) != null ? var.default_pool.pod_subnet_id : null
    zones                        = var.default_pool.availability_zones
    enable_auto_scaling          = var.default_pool.auto_scaling
    fips_enabled                 = var.default_pool.fips_enabled
    only_critical_addons_enabled = lookup(var.default_pool, "only_critical_addons_enabled", false)

    kubelet_config {}
  }


  # Pod settings
  linux_profile {
    admin_username = var.linux_admin_username
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  # Addons
  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider.enabled == true ? ["a"] : []
    content {
      secret_rotation_enabled  = var.key_vault_secrets_provider.secret_rotation_enabled
      secret_rotation_interval = var.key_vault_secrets_provider.secret_rotation_interval
    }
  }

  oms_agent {
    log_analytics_workspace_id      = local.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = local.msi_auth
  }

  dynamic "microsoft_defender" {
    for_each = var.enable_audit_logs != false ? ["a"] : []
    content {
      log_analytics_workspace_id = local.log_analytics_workspace_id
    }
  }

  dynamic "monitor_metrics" {
    for_each = var.monitor_metric != null ? ["a"] : []
    content {
      annotations_allowed = var.monitor_metric.annotations_allowed
      labels_allowed      = var.monitor_metric.labels_allowed
    }
  }
  #Proxy settings (optional)
  http_proxy_config {
    http_proxy  = var.http_proxy_config.http_proxy
    https_proxy = var.http_proxy_config.https_proxy
    no_proxy    = var.http_proxy_config.no_proxy
    trusted_ca  = var.http_proxy_config.trusted_ca
  }

  storage_profile {
    blob_driver_enabled         = var.storage_profile.blob_driver_enabled
    disk_driver_enabled         = var.storage_profile.disk_driver_enabled
    disk_driver_version         = var.storage_profile.disk_driver_version
    file_driver_enabled         = var.storage_profile.file_driver_enabled
    snapshot_controller_enabled = var.storage_profile.snapshot_controller_enabled
  }

  depends_on = [
    azurerm_role_assignment.rbac_assign_dns,
    azurerm_role_assignment.rbac_assign_udr,
    azurerm_role_assignment.rbac_assign_vnet
  ]

  lifecycle {
    ignore_changes = [
      tags["costcenter"],
      tags["env"],
      tags["owner"],
      tags["owneremail"],
      tags["ownerresgroup"],
      tags["scope"],
      tags["tier"],
      tags["workload"],
      tags["publicip"],
      http_proxy_config,
      microsoft_defender,
    ]
  }
}

module "lifecycle" {
  source     = "../ccoe.product.tools.lifecycle//module?ref=0.2.0"
  depends_on = [azurerm_kubernetes_cluster.aks]

  resource_id   = azurerm_kubernetes_cluster.aks.id
  environment   = var.environment
  workload_name = var.workload_name
}
