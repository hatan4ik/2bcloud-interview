module "aks" {
  # Please uncomment the source and set the version before using insted of the current source line.
  # source = "../ccoe.product.aks//module?ref=1.5.1"
  source = "../module"

  location                   = local.location
  workload_name              = random_string.workload_name.result
  environment                = local.environment
  resource_group_name        = azurerm_resource_group.this.name
  aks_dns_prefix             = random_string.workload_name.result
  aks_dns_zone_id            = data.azurerm_private_dns_zone.aks_private_dns_zone.id
  managed_identity           = azurerm_user_assigned_identity.aks_mi
  log_analytics_workspace_id = module.workspace_resolver.log_analytics_workspace_id

  cluster_admin_role_object_ids      = [data.azurerm_client_config.current.object_id]
  cluster_user_role_object_ids       = [data.azurerm_client_config.current.object_id]
  rbac_cluster_admin_role_object_ids = [data.azurerm_client_config.current.object_id]
  contributor_role_object_ids        = [data.azurerm_client_config.current.object_id]

  default_pool = {
    node_size          = "Standard_DS2_v2"
    node_count         = 3
    auto_scaling       = false
    availability_zones = []
    subnet_id          = data.azurerm_subnet.spoke.id
    fips_enabled       = true
    #only_critical_addons_enabled    = true
  }

  linux_admin_username = "sesadmin"
  ssh_public_key       = tls_private_key.ssh.public_key_openssh

  # Whilst the AKS API previously supported the 'Paid' SKU.
  # The AKS API introduced a breaking change in API Version 2023-02-01 (used in v3.51.0 and later) where the value Paid must now be set to Standard.
  sku = "Standard"

  #Optional. Configure the Azure Policy in AKS
  #azure_policy_enabled = true

  #Optional. Configure AKS to use a proxy
  #http_proxy_config = {
  #  http_proxy = "http://10.56.4.41:8080/"
  #  https_proxy = "http://10.56.4.41:8080/"
  #  no_proxy = [
  #     "localhost",
  #     "127.0.0.1",
  #     "172.16.0.0/12",
  #     "hcp.westeurope.azmk8s.io",
  #     "privatelink.westeurope.azmk8s.io",
  #     "hcp.eastus.azmk8s.io",
  #     "privatelink.eastus.azmk8s.io",
  #     ".svc",
  #     ".cluster.local",
  #     "kubernetes.default",
  #      ".default"
  #  ]
  #  trusted_ca = "proxy-certificate-base-64-encoded-return-line-replace-by-\n"
  #}
}
