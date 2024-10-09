<!-- BEGIN_TF_DOCS -->
# Azure Keyvault

This product will deploy a keyvault following SES standards.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.36.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.36.0 |

## Sample

<details>
<summary>Click to expand</summary>

```hcl
module "keyvault" {
  # source              = "../ccoe.product.keyvault//module?ref=4.7.0"
  source = "../module"

  resource_group_name                  = azurerm_resource_group.group.name
  environment                          = local.environment
  workload_name                        = random_string.workload_name.result
  location                             = local.location
  enabled_for_vm_deployment            = false
  enabled_for_disk_encryption          = true
  admin_role_object_ids                = [data.azurerm_client_config.current.object_id]
  reader_role_object_ids               = [data.azurerm_client_config.current.object_id]
  certificates_officer_role_object_ids = [data.azurerm_client_config.current.object_id]

  #If you want to deploy private endpoint for Key Vault private_endpoint_subnet_id should be provided. This will be the id of the subnet that private endpoint will use.
  private_endpoint = {
    "my_kvt_pep" = {
      subnet_id          = data.azurerm_subnet.spoke.id
      private_ip_address = "10.57.50.56"
    }
  }

  optional_tags = azurerm_resource_group.group.tags
}
```
### For a complete deployment example, please check [sample folder](/samples).
</details>

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_role_object_ids"></a> [admin\_role\_object\_ids](#input\_admin\_role\_object\_ids) | List of object IDs to be added with admin role on Key Vault. The service principal object ID for admin role is mandatory. | `list(string)` | n/a | yes |
| <a name="input_authorized_ips_or_cidr_blocks"></a> [authorized\_ips\_or\_cidr\_blocks](#input\_authorized\_ips\_or\_cidr\_blocks) | One or more IP Addresses, or CIDR Blocks which should be able to access the Key Vault. | `list(string)` | `[]` | no |
| <a name="input_authorized_vnet_subnet_ids"></a> [authorized\_vnet\_subnet\_ids](#input\_authorized\_vnet\_subnet\_ids) | IDs of the virtual network subnets authorized to connect to the Key Vault. | `list(string)` | `[]` | no |
| <a name="input_certificates_officer_role_object_ids"></a> [certificates\_officer\_role\_object\_ids](#input\_certificates\_officer\_role\_object\_ids) | List of object IDs to be added with Key Vault Certificates Officer role on Key Vault. | `list(string)` | `[]` | no |
| <a name="input_crypto_encryption_role_object_ids"></a> [crypto\_encryption\_role\_object\_ids](#input\_crypto\_encryption\_role\_object\_ids) | List of object IDs to be added with Key Vault Crypto Service Encryption User role on Key Vault. | `list(string)` | `[]` | no |
| <a name="input_crypto_officer_role_object_ids"></a> [crypto\_officer\_role\_object\_ids](#input\_crypto\_officer\_role\_object\_ids) | List of object IDs to be added with Key Vault Crypto Officer role on Key Vault. | `list(string)` | `[]` | no |
| <a name="input_crypto_user_role_object_ids"></a> [crypto\_user\_role\_object\_ids](#input\_crypto\_user\_role\_object\_ids) | List of object IDs to be added with Key Vault Crypto User role on Key Vault. | `list(string)` | `[]` | no |
| <a name="input_enabled_for_agw_deployment"></a> [enabled\_for\_agw\_deployment](#input\_enabled\_for\_agw\_deployment) | Boolean flag to specify whether Azure Application Gateway are permitted to retrieve certificates stored as secrets from the Key Vault. | `bool` | `false` | no |
| <a name="input_enabled_for_disk_encryption"></a> [enabled\_for\_disk\_encryption](#input\_enabled\_for\_disk\_encryption) | Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. | `bool` | `false` | no |
| <a name="input_enabled_for_sql_deployment"></a> [enabled\_for\_sql\_deployment](#input\_enabled\_for\_sql\_deployment) | Boolean flag to specify whether Azure SQL is permitted to retrieve keys from the Key Vault. | `bool` | `false` | no |
| <a name="input_enabled_for_template_deployment"></a> [enabled\_for\_template\_deployment](#input\_enabled\_for\_template\_deployment) | Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the Key Vault. | `bool` | `false` | no |
| <a name="input_enabled_for_vm_deployment"></a> [enabled\_for\_vm\_deployment](#input\_enabled\_for\_vm\_deployment) | Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the Key Vault. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development', 'Production' and 'Global'. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. alid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive). | `string` | n/a | yes |
| <a name="input_optional_tags"></a> [optional\_tags](#input\_optional\_tags) | Optional tags for the Azure Key Vault. Please set a value for the key `supportResGroup` when support is not provided by the ownerResGroup team, but by a specialized team (such as IT Systems Operations, IT Network Operations, etc.). This tag should be defined, when required,on each CCoE product template (IaC), and applied automatically during deployment. Typically, a Distribution List to enable sending relevant notifications and information (e.g. in case of incidents, planned maintenances, new available components) from Azure or also the ITSM tool. Tag value will be requested and provided during the workload intake process. | `map(string)` | `{}` | no |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | This block requires following inputs:<br> -`subnet_id (required)`: The ID of the Subnet within which the KeyVault should be deployed. <br> private\_ip\_address (Optional): Private IP Address assign to the Private Endpoint. The last one and first four IPs in any range are reserved and cannot be manually assigned. | <pre>map(object({<br>    subnet_id          = string<br>    private_ip_address = optional(string)<br>  }))</pre> | `{}` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Enable public access from specific virtual networks and IP addresses. When the value is `false`, clients can only use the private endpoint to communicate with the storage. | `bool` | `true` | no |
| <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled) | Is Purge Protection enabled for this Key Vault? | `bool` | `false` | no |
| <a name="input_reader_role_object_ids"></a> [reader\_role\_object\_ids](#input\_reader\_role\_object\_ids) | List of object IDs to be added with reader role on Key Vault. | `list(string)` | `[]` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The resource group where to deploy the Key Vault. | `string` | n/a | yes |
| <a name="input_secrets_officer_role_object_ids"></a> [secrets\_officer\_role\_object\_ids](#input\_secrets\_officer\_role\_object\_ids) | List of object IDs to be added with Key Vault Secrets Officer role on Key Vault. | `list(string)` | `[]` | no |
| <a name="input_secrets_user_role_object_ids"></a> [secrets\_user\_role\_object\_ids](#input\_secrets\_user\_role\_object\_ids) | List of object IDs to be added with Key Vault Secrets User role on Key Vault. | `list(string)` | `[]` | no |
| <a name="input_sequence_number"></a> [sequence\_number](#input\_sequence\_number) | Sequence number to be defined according to naming convention. | `number` | `1` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. By default, Key Vault will set this value to 7. | `number` | `7` | no |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | Specifies the workload name that will use this resource. This will be used in the resource name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The ID of the created Azure Key Vault resource. |
| <a name="output_name"></a> [name](#output\_name) | The name of the created Azure Key Vault resource. |
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) | The private endpoint Id of KeyVault |
| <a name="output_private_endpoint_name"></a> [private\_endpoint\_name](#output\_private\_endpoint\_name) | The private endpoint name of KeyVault |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_private_endpoint.private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lifecycle"></a> [lifecycle](#module\_lifecycle) | ../ccoe.product.tools.lifecycle//module | 0.2.0 |
| <a name="module_names"></a> [names](#module\_names) | ../ccoe.product.naming//module | 0.10.0 |
| <a name="module_private_endpoint_names"></a> [private\_endpoint\_names](#module\_private\_endpoint\_names) | ../ccoe.product.naming//module | 0.10.0 |
| <a name="module_role_assignment"></a> [role\_assignment](#module\_role\_assignment) | ../ccoe.product.tools.rbac//module | 0.2.0 |
<!-- END_TF_DOCS -->