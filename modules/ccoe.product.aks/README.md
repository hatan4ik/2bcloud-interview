<!-- BEGIN_TF_DOCS -->
# Azure Kubernetes Service

This product will deploy an AKS cluster following SES standards.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.71.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.71.0 |

## Sample

<details>
<summary>Click to expand</summary>

```hcl
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
```
### For a complete deployment example, please check [sample folder](/samples).
</details>

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_dns_prefix"></a> [aks\_dns\_prefix](#input\_aks\_dns\_prefix) | DNS prefix for the cluster. Will be used as part of the FQDN for the cluster. | `string` | n/a | yes |
| <a name="input_aks_dns_zone_id"></a> [aks\_dns\_zone\_id](#input\_aks\_dns\_zone\_id) | ID of the Private DNS Zone to use for the AKS cluster. | `string` | n/a | yes |
| <a name="input_aks_kubernetes_version"></a> [aks\_kubernetes\_version](#input\_aks\_kubernetes\_version) | Version of Kubernetes specified when creating the AKS managed cluster. If not specified, the latest recommended version will be used at provisioning time (but won't auto-upgrade). | `string` | `null` | no |
| <a name="input_azure_policy_enabled"></a> [azure\_policy\_enabled](#input\_azure\_policy\_enabled) | Enable the Azure Policy Add-On. | `bool` | `false` | no |
| <a name="input_cluster_admin_role_object_ids"></a> [cluster\_admin\_role\_object\_ids](#input\_cluster\_admin\_role\_object\_ids) | List of object IDs to be added with Cluster Admin role on Azure Kubernetes Service. The service principal object ID for cluster admin role is mandatory. | `list(string)` | n/a | yes |
| <a name="input_cluster_user_role_object_ids"></a> [cluster\_user\_role\_object\_ids](#input\_cluster\_user\_role\_object\_ids) | List of object IDs to be added with Cluster User role on Azure Kubernetes Service. | `list(string)` | `[]` | no |
| <a name="input_contributor_role_object_ids"></a> [contributor\_role\_object\_ids](#input\_contributor\_role\_object\_ids) | List of object IDs to be added with Contributor role on Azure Kubernetes Service. | `list(string)` | `[]` | no |
| <a name="input_default_pool"></a> [default\_pool](#input\_default\_pool) | Settings for the default node pool. WARNING: when modifying the `node_size` you may face side effects that have been documented under the [wiki](https://dev.azure.com/SES-CCoE/SES%20CCoE%20Public/_wiki/wikis/SES-CCoE-Public.wiki/7494/AKS-scale-up-out-down). | <pre>object({<br>    node_size                    = string<br>    node_count                   = number<br>    auto_scaling                 = bool<br>    availability_zones           = list(string)<br>    enable_node_public_ip        = optional(bool)<br>    subnet_id                    = string<br>    pod_subnet_id                = optional(string)<br>    fips_enabled                 = optional(bool)<br>    only_critical_addons_enabled = optional(bool)<br>  })</pre> | n/a | yes |
| <a name="input_ebpf_option"></a> [ebpf\_option](#input\_ebpf\_option) | AKS ebpf\_data\_plane to use. Allowed value is 'cilium'. If null and cilium is preferred to be used, then please set default node pool with subnet id which to be used. | `string` | `null` | no |
| <a name="input_enable_audit_logs"></a> [enable\_audit\_logs](#input\_enable\_audit\_logs) | Enable if the audit logs needs to be collected by Microsoft Defender. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development', 'Production' and 'Global'. | `string` | n/a | yes |
| <a name="input_http_proxy_config"></a> [http\_proxy\_config](#input\_http\_proxy\_config) | Proxy settings. WARNING: the settings cannot be updated once the server is created, including the `noproxy` setting. If you need to update this setting, please use the `az` CLI. | <pre>object({<br>    http_proxy  = string<br>    https_proxy = string<br>    no_proxy    = list(string)<br>    trusted_ca  = string<br>  })</pre> | <pre>{<br>  "http_proxy": null,<br>  "https_proxy": null,<br>  "no_proxy": null,<br>  "trusted_ca": null<br>}</pre> | no |
| <a name="input_key_vault_secrets_provider"></a> [key\_vault\_secrets\_provider](#input\_key\_vault\_secrets\_provider) | Enables and configures the CSI secrets driver for Azure Keyvault.<br>  - `enabled`: Enables the driver. Defaults to `true`.<br>  - `secret_rotation_enabled`: Enable rotation of secrets. Defaults to `false`.<br>  - `secret_rotation_interval`: Sets the secret rotation interval. Only used when `secret_rotation_enabled` is true, the default is `2m`. | <pre>object({<br>    enabled                  = bool<br>    secret_rotation_enabled  = bool<br>    secret_rotation_interval = string<br>  })</pre> | <pre>{<br>  "enabled": true,<br>  "secret_rotation_enabled": false,<br>  "secret_rotation_interval": "2m"<br>}</pre> | no |
| <a name="input_linux_admin_username"></a> [linux\_admin\_username](#input\_linux\_admin\_username) | The admin username for the Cluster. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_load_balancer_sku"></a> [load\_balancer\_sku](#input\_load\_balancer\_sku) | Specifies the SKU of the Load Balancer used for this Kubernetes Cluster. Possible values are basic and standard. Defaults to standard. Changing this forces a new resource to be created. | `string` | `"standard"` | no |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Valid options are West Europe and East US (case and whitespaces insensitive). | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | The ID of Log Analytics workspace where the OMS Agent logs will be stored. | `string` | n/a | yes |
| <a name="input_managed_identity"></a> [managed\_identity](#input\_managed\_identity) | The managed identity that will be used to run the cluster and kubelets. | `any` | n/a | yes |
| <a name="input_monitor_metric"></a> [monitor\_metric](#input\_monitor\_metric) | Prometheus add-on profile for the Kubernetes Cluster. This is required when deploying Managed Prometheus with existing Azure Monitor Workspace.<br>  - `annotations_allowed`: The list of Kubernetes annotation keys that will be used in the resource's labels metric.<br>  - `labels_allowed`: A comma separated list of additional kuberenetes label keys that will be used in the resource's labels metric. | <pre>object({<br>    annotations_allowed = string<br>    labels_allowed      = string<br>  })</pre> | `null` | no |
| <a name="input_network_lb_config"></a> [network\_lb\_config](#input\_network\_lb\_config) | Enables and configures the network load balancer configuration.<br>  - `idle_timeout`: Desired outbound flow idle timeout in minutes for the cluster load balancer. Must be between 4 and 120 inclusive. Defaults to 30.<br>  - `outbound_ip_count`: Count of desired managed outbound IPs for the cluster load balancer. Must be between 1 and 100 inclusive.<br>  - `outbound_ports_allocated`: Number of desired SNAT port for each VM in the clusters load balancer. Must be between 0 and 64000 inclusive. Defaults to 0. | <pre>object({<br>    idle_timeout             = optional(number)<br>    outbound_ip_count        = optional(number)<br>    outbound_ports_allocated = optional(number)<br>  })</pre> | `{}` | no |
| <a name="input_network_plugin"></a> [network\_plugin](#input\_network\_plugin) | AKS network plugin to use. Allowed values are 'azure' and 'kubenet'. Defaults to 'kubenet'. When 'kubenet' is used the network used for the pods is 172.28.0.0/16 which is aligned with SES IT IP address management. | `string` | `"kubenet"` | no |
| <a name="input_network_plugin_mode"></a> [network\_plugin\_mode](#input\_network\_plugin\_mode) | AKS network plugin Mode for azure network plugin. Allowed value is 'overlay'. | `string` | `null` | no |
| <a name="input_node_resource_group"></a> [node\_resource\_group](#input\_node\_resource\_group) | The name of the Resource Group where the Kubernetes Nodes should exist. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_oidc_issuer_enabled"></a> [oidc\_issuer\_enabled](#input\_oidc\_issuer\_enabled) | Enable the OIDC issuer for Azure Kubernetes Service. | `bool` | `false` | no |
| <a name="input_optional_tags"></a> [optional\_tags](#input\_optional\_tags) | Optional tags for the AKS resources. Please set a value for the key `supportResGroup` when support is not provided by the ownerResGroup team, but by a specialized team (such as IT Systems Operations, IT Network Operations, etc.). This tag should be defined, when required,on each CCoE product template (IaC), and applied automatically during deployment. Typically, a Distribution List to enable sending relevant notifications and information (e.g. in case of incidents, planned maintenances, new available components) from Azure or also the ITSM tool. Tag value will be requested and provided during the workload intake process. | `map(string)` | `{}` | no |
| <a name="input_outbound_type"></a> [outbound\_type](#input\_outbound\_type) | Specifies the outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are loadBalancer, userDefinedRouting. Defaults to loadBalancer. | `string` | `"loadBalancer"` | no |
| <a name="input_rbac_admin_role_object_ids"></a> [rbac\_admin\_role\_object\_ids](#input\_rbac\_admin\_role\_object\_ids) | List of object IDs to be added with RBAC Admin role on Azure Kubernetes Service. | `list(string)` | `[]` | no |
| <a name="input_rbac_cluster_admin_role_object_ids"></a> [rbac\_cluster\_admin\_role\_object\_ids](#input\_rbac\_cluster\_admin\_role\_object\_ids) | List of object IDs to be added with RBAC Cluster Admin role on Azure Kubernetes Service. | `list(string)` | `[]` | no |
| <a name="input_rbac_reader_role_object_ids"></a> [rbac\_reader\_role\_object\_ids](#input\_rbac\_reader\_role\_object\_ids) | List of object IDs to be added with RBAC Reader role on Azure Kubernetes Service. | `list(string)` | `[]` | no |
| <a name="input_rbac_writer_role_object_ids"></a> [rbac\_writer\_role\_object\_ids](#input\_rbac\_writer\_role\_object\_ids) | List of object IDs to be added with RBAC Writer role on Azure Kubernetes Service. | `list(string)` | `[]` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the resource | `string` | n/a | yes |
| <a name="input_sequence_number"></a> [sequence\_number](#input\_sequence\_number) | When using count on the module, you should provide a sequence number that will be the storage account name suffix. It must be an integer. | `number` | `1` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | The SKU Tier that should be used for this Kubernetes Cluster. Possible values are 'Free', 'Paid' and 'Standard'. Defaults to Free. <br> Whilst the AKS API previously supported the 'Paid' SKU - the AKS API introduced a breaking change in API Version 2023-02-01 (used in v3.51.0 and later) where the value Paid must now be set to Standard. | `string` | `"Free"` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key used be the linux admin account to access pods. | `string` | n/a | yes |
| <a name="input_storage_profile"></a> [storage\_profile](#input\_storage\_profile) | Configure the Azure container storage interface (CSI).<br>  - `blob_driver_enabled`: Enable the blob driver to mount storage account container in Kubernetes container. Defaults to `false`.<br>  - `disk_driver_enabled`: Enable the disk driver to mount Azure disk in Kubernetes container. Defaults to `true`.<br>  - `disk_driver_version`: The version of the disk driver to use. Possible values are `v1` and `v2`. Defaults to `v1`. <br>                           The version 2 is in public preview, please review the prerequisites under [this terraform page](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#storage_profile)<br>  - `file_driver_enabled`: Enable the file driver to mount Azure storage file in Kubernetes container. Defaults to `true`.<br>  - `snapshot_controller_enabled` : Enable the snapshot controller to manage backup from AKS. Defaults to `true`. Further information is available under [this Microsoft article](snapshot\_controller\_enabled). | <pre>object({<br>    blob_driver_enabled         = bool<br>    disk_driver_enabled         = bool<br>    disk_driver_version         = string<br>    file_driver_enabled         = bool<br>    snapshot_controller_enabled = bool<br>  })</pre> | <pre>{<br>  "blob_driver_enabled": false,<br>  "disk_driver_enabled": true,<br>  "disk_driver_version": "v1",<br>  "file_driver_enabled": true,<br>  "snapshot_controller_enabled": true<br>}</pre> | no |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | Specifies the workload name that will use this resource. This will be used in the resource name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_certificate"></a> [client\_certificate](#output\_client\_certificate) | Client Certificate for this Managed Kubernetes Cluster. |
| <a name="output_client_key"></a> [client\_key](#output\_client\_key) | Client Keys for this Managed Kubernetes Cluster. |
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | Client CA Certificate for this Managed Kubernetes Cluster. |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | The FQDN of the Azure Kubernetes Managed Cluster. |
| <a name="output_host"></a> [host](#output\_host) | Host details for this Managed Kubernetes Cluster. |
| <a name="output_id"></a> [id](#output\_id) | The Kubernetes Managed Cluster ID. |
| <a name="output_identity"></a> [identity](#output\_identity) | A managed identity block for this Managed Kubernetes Cluster. |
| <a name="output_key_vault_secrets_provider"></a> [key\_vault\_secrets\_provider](#output\_key\_vault\_secrets\_provider) | Keyvault secrets driver configuration for this cluster. |
| <a name="output_kube_admin_config"></a> [kube\_admin\_config](#output\_kube\_admin\_config) | A kube\_admin\_config block. This is only available when Role Based Access Control with Azure Active Directory is enabled. |
| <a name="output_kube_admin_config_raw"></a> [kube\_admin\_config\_raw](#output\_kube\_admin\_config\_raw) | Raw Kubernetes config for the admin account to be used by kubectl and other compatible tools. This is only available when Role Based Access Control with Azure Active Directory is enabled. |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | A kube\_config block. |
| <a name="output_kube_config_raw"></a> [kube\_config\_raw](#output\_kube\_config\_raw) | Raw Kubernetes config to be used by kubectl and other compatible tools. |
| <a name="output_kubelet_identity"></a> [kubelet\_identity](#output\_kubelet\_identity) | A kubelet\_identity block |
| <a name="output_name"></a> [name](#output\_name) | The Kubernetes Managed Cluster name. |
| <a name="output_node_resource_group"></a> [node\_resource\_group](#output\_node\_resource\_group) | Resource Group which contains the resources for this Managed Kubernetes Cluster. |
| <a name="output_node_resource_group_id"></a> [node\_resource\_group\_id](#output\_node\_resource\_group\_id) | The ID of the Resource Group containing the resources for this Managed Kubernetes Cluster. |
| <a name="output_oidc_issuer_enabled"></a> [oidc\_issuer\_enabled](#output\_oidc\_issuer\_enabled) | Whether or not the OIDC feature is enabled or disabled. |
| <a name="output_oidc_issuer_url"></a> [oidc\_issuer\_url](#output\_oidc\_issuer\_url) | The OIDC issuer URL that is associated with the cluster. |
| <a name="output_password"></a> [password](#output\_password) | Passwords for this Managed Kubernetes Cluster. |
| <a name="output_private_fqdn"></a> [private\_fqdn](#output\_private\_fqdn) | The FQDN for the Kubernetes Cluster when private link has been enabled, which is only resolvable inside the Virtual Network used by the Kubernetes Cluster. |
| <a name="output_username"></a> [username](#output\_username) | Usernames for this Managed Kubernetes Cluster. |

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster.aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_role_assignment.rbac_assign_dns](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.rbac_assign_udr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.rbac_assign_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_central_workspace_resolver"></a> [central\_workspace\_resolver](#module\_central\_workspace\_resolver) | ../ccoe.product.tools.workspaceresolver//module | 0.2.0 |
| <a name="module_k8s_name"></a> [k8s\_name](#module\_k8s\_name) | ../ccoe.product.naming//module | 0.9.0 |
| <a name="module_lifecycle"></a> [lifecycle](#module\_lifecycle) | ../ccoe.product.tools.lifecycle//module | 0.2.0 |
| <a name="module_role_assignment"></a> [role\_assignment](#module\_role\_assignment) | ../ccoe.product.tools.rbac//module | 0.2.0 |
<!-- END_TF_DOCS -->