locals {
  default_tags = {
    CCoESolVersion = "AKSv1.5.1"
    publicip       = "aks"
  }
  tags                = merge(var.optional_tags, local.default_tags)
  location_identifier = lookup({ "westeurope" = "weu1", "eastus" = "eus1" }, lower(replace(var.location, " ", "")))

  // pod_cidr is only used when networking plugin is kubenet. Hardcoded IP is assigned for this purpose in SES IPAM.
  pod_cidr = var.network_plugin == "kubenet" || (var.network_plugin_mode == "overlay" && var.ebpf_option == "cilium") ? "172.28.0.0/16" : null

  vnet_split                = split("/", var.default_pool.subnet_id)
  vnet_rg_name              = element(local.vnet_split, 4)
  vnet_name                 = element(local.vnet_split, 8)
  snet_name                 = element(local.vnet_split, 10)
  custom_workspace_provided = var.log_analytics_workspace_id != null
  log_analytics_workspace_id = (
    local.custom_workspace_provided ?
    var.log_analytics_workspace_id :
    module.central_workspace_resolver.log_analytics_workspace_id
  )
  msi_auth = var.monitor_metric != null ? true : false
}
