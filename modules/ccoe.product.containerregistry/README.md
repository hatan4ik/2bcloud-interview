<!-- BEGIN_TF_DOCS -->
# CCoE Azure Container Registry

This module will deploy an Azure Container Registry compliant with SES Security and MSM controls.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >=1.6.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.36.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.36.0 |

## Sample

<details>
<summary>Click to expand</summary>

```hcl
module "acr" {
  # source = "../ccoe.product.containerregistry//module?ref=4.2.0"
  source = "../module"

  environment              = local.environment
  location                 = local.location
  resource_group_name      = azurerm_resource_group.rg.name
  workload_name            = random_string.workload_name.result
  georeplication_locations = ["northeurope", "westeurope"]

  # Public IP range for ADO services to access private ACR.
  # This is only required only if user trying to push image but not using separate ADO agents.
  #authorized_ips_or_cidr_blocks = ["52.168.115.0/24"]

  # Here you can provide a list of object ids that need to be able to pull images from Azure Container Registry
  # In a DevOps team context, a service principal is created by the platform team you may want to use it (or not)
  # You can also provide the object_id of a service principal (Managed Identity for example) created within your Terraform
  image_pull_service_principal_ids = [
    data.azuread_service_principal.workload_service_principal.id
  ]

  image_push_service_principal_ids = [
    data.azuread_service_principal.workload_service_principal.id
  ]

  optional_tags = {
    supportResGroup = azurerm_resource_group.rg.name
  }

  #If you want to deploy private endpoint for ACR private_endpoint_subnet_id should be provided. This will be the id of the subnet that private endpoint will use.
  private_endpoint = {
    "my_pep" = {
      subnet_id = data.azurerm_subnet.spoke.id
      ip_configuration = [
        {
          member_name        = "registry"
          private_ip_address = "10.57.50.61"
        },
        #When static IP is used in ACR private endpoint, a second IP configuration must be added, with the member_name
        # "registry_data_<ACR location>".
        {
          member_name        = "registry_data_eastus"
          private_ip_address = "10.57.50.62"
        },
        #When static IP is used in ACR private endpoint and georeplivation is enabled, a second IP configuration
        # 3 IP additional configurations should be present: "registry_data_<ACR location>", "registry_data_<first ACR georeplication location>"
        # and "registry_data_<second ACR georeplication location>".
        {
          member_name        = "registry_data_westeurope"
          private_ip_address = "10.57.50.63"
        },
        {
          member_name        = "registry_data_northeurope"
          private_ip_address = "10.57.50.64"
        },
      ]
    }
  }
}

resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = "${path.module}/app1/docker-push-image-to-acr.ps1 -RegistryName ${module.acr.name}"

    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [module.acr]
}
```
### For a complete deployment example, please check [sample folder](/samples).
</details>

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_customer_managed_keys"></a> [customer\_managed\_keys](#input\_customer\_managed\_keys) | Specifies customer managed keys configuration. This block requires the following inputs:<br> - `cmk_enabled`: If Customer Managed Key needs to be enabled?<br> - `user_managed_identity_id` Managed Identity ID that will be assigned to the ACR. <br> - `user_managed_identity_clientid` Managed Identity Client ID that will be assigned to the ACR. <br> - `keyvault_id` Key Vault's id where the key will be stored.<br> - `kvt_key_id` KeyVault's Key id to be used for encryption. | <pre>object({<br>    cmk_enabled                    = bool<br>    user_managed_identity_id       = string<br>    user_managed_identity_clientid = string<br>    keyvault_id                    = string<br>    kvt_key_id                     = string<br>  })</pre> | <pre>{<br>  "cmk_enabled": false,<br>  "keyvault_id": "",<br>  "kvt_key_id": "",<br>  "user_managed_identity_clientid": "",<br>  "user_managed_identity_id": ""<br>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development' and 'Production'. | `string` | n/a | yes |
| <a name="input_georeplication_locations"></a> [georeplication\_locations](#input\_georeplication\_locations) | Specifies the supported Azure location for geo replication. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive). | `list(string)` | `null` | no |
| <a name="input_image_pull_service_principal_ids"></a> [image\_pull\_service\_principal\_ids](#input\_image\_pull\_service\_principal\_ids) | List of Service Principal object IDs to be added with AcrPull role on Azure Container Registry. | `list(string)` | `[]` | no |
| <a name="input_image_push_service_principal_ids"></a> [image\_push\_service\_principal\_ids](#input\_image\_push\_service\_principal\_ids) | List of Service Principal object IDs to be added with AcrPush role on Azure Container Registry. | `list(string)` | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_optional_tags"></a> [optional\_tags](#input\_optional\_tags) | Optional tags for the Azure Container Registry. This block requires the following inputs:<br>  - `supportResGroup`: The SupportResGroup is to be used when support is not provided by the ownerResGroup team, but by a specialized team (such as IT Systems Operations, IT Network Operations, etc.). This tag should be defined, when required,on each CCoE product template (IaC), and applied automatically during deployment. Typically, a Distribution List to enable sending relevant notifications and information (e.g. in case of incidents, planned maintenances, new available components) from Azure or also the ITSM tool. Tag \_ value to be requested and provided during the workload intake process. | `map(string)` | `{}` | no |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | Specifies the private endpoint details for ACR. This block requires the following inputs:<br>  - `subnet_id`: The subnet ID to use for the private endpoint of the ACR. <br> - `ip_configuration`: This block is optional and contains the following inputs:<br> -`private_ip_address`: The static IP addres for the ACR private endpoint.<br> - `member_name`: The member name this IP applies to. | <pre>map(object({<br>    subnet_id = string<br>    ip_configuration = optional(list(object({<br>      member_name        = string<br>      private_ip_address = string<br>    })))<br>  }))</pre> | `{}` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The resource group to deploy the Azure Container Registry. | `string` | n/a | yes |
| <a name="input_sequence_number"></a> [sequence\_number](#input\_sequence\_number) | When using count on the module, you should provide a sequence number that will be the Azure Container Registry name suffix. It must be an integer. | `number` | `1` | no |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | Specifies the workload name that will use this resource. This will be used in the resource name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | ID of the Azure Container Registry. |
| <a name="output_name"></a> [name](#output\_name) | Name of the Azure Container Registry. |
| <a name="output_url"></a> [url](#output\_url) | Azure Container Registry Login Server details. |

## Resources

| Name | Type |
|------|------|
| [azurerm_container_registry.acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_private_endpoint.private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lifecycle"></a> [lifecycle](#module\_lifecycle) | ../ccoe.product.tools.lifecycle//module | 0.2.0 |
| <a name="module_names"></a> [names](#module\_names) | ../ccoe.product.naming//module | 0.9.0 |
| <a name="module_private_endpoints_names"></a> [private\_endpoints\_names](#module\_private\_endpoints\_names) | ../ccoe.product.naming//module | 0.9.0 |
| <a name="module_rbac"></a> [rbac](#module\_rbac) | ../ccoe.product.tools.rbac//module | 0.2.0 |
<!-- END_TF_DOCS -->