<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.20.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.20.0 |

## Sample

<details>
<summary>Click to expand</summary>

```hcl
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "=1.6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.80.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.4.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = false
    }
  }
}

provider "azurerm" {
  alias           = "corpmgmt"
  subscription_id = "9edfcf94-ddb7-4d37-a1c8-2461e649c328"
  features {}
}

locals {
  environment = "Development"
  location    = "East US"
}

resource "random_string" "workload_name" {
  length  = 9
  special = false
  numeric = false
  upper   = false
}

module "names" {
  source = "../ccoe.product.naming//module?ref=0.11.0"

  environment     = local.environment
  location        = local.location
  workload_name   = random_string.workload_name.result
  suffix          = "aci"
  sequence_number = 21
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = module.names.resource_group

  tags = {
    "scope"         = "application",
    "tier"          = "aci",
    "env"           = local.environment,
    "workload"      = random_string.workload_name.result,
    "owner"         = "georgiana ilici",
    "owneremail"    = "georgiana.ilici@ses.com",
    "customeremail" = "-",
    "costcenter"    = "2650088",
    "lifecycle"     = "pipeline" #This tag is used for Product Team internal workflow only. Please remove if copying.
  }
}
```
### For a complete deployment example, please check [sample folder](/samples).
</details>

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_containers"></a> [containers](#input\_containers) | The containers to run on the Azure Container Instance. This block requires the following inputs:<br>  - `name`: The name of the container.<br>  - `image_name`: The name of the Docker Image in the registry.<br>  - `tag`: The tag of the image to use to run the container.<br>  - `cpu`: The amount of CPU to provide to the container.<br>  - `memory`: The amount of Memory in GB to provide to the container.<br>  - `ports`: The list of ports to bind to the container.  This block requires the following inputs:<br>    - `port`: The port number.<br>    - `protocol`: The protocol associated with the binded port.<br>  - `volume`: The volume to mount to the container.  This block requires the following inputs:<br>  - `mount_path`: The path where to mount the volume.<br>  - `name`: The volume name.<br>  - `share_name`: The Azure Storage Account file share name to use.<br>  - `storage_account_name`: The name of the storage account where the file share exists.<br>  - `storage_account_key`: The storage account access key. | <pre>list(object({<br>    name       = string<br>    image_name = string<br>    tag        = string<br>    cpu        = number<br>    memory     = number<br>    ports = list(object({<br>      port     = number<br>      protocol = string<br>    }))<br>    volume = object({<br>      name                 = string<br>      mount_path           = string<br>      share_name           = string<br>      storage_account_key  = string<br>      storage_account_name = string<br>    })<br>  }))</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development' and 'Production'. | `string` | n/a | yes |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Map of non-sensitive environment variables to set on the Azure Container Instance. | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive). | `string` | n/a | yes |
| <a name="input_optional_tags"></a> [optional\_tags](#input\_optional\_tags) | Optional tags for the Azure Container Instances. Please set a value for the key `supportResGroup` when support is not provided by the ownerResGroup team, but by a specialized team (such as IT Systems Operations, IT Network Operations, etc.). This tag should be defined, when required,on each CCoE product template (IaC), and applied automatically during deployment. Typically, a Distribution List to enable sending relevant notifications and information (e.g. in case of incidents, planned maintenances, new available components) from Azure or also the ITSM tool. Tag value will be requested and provided during the workload intake process. | `map(string)` | `{}` | no |
| <a name="input_registry"></a> [registry](#input\_registry) | The Azure Container Registry from where to pull the image(s). This block requires the following inputs:<br>  - `name`: The name of the Azure Container Registry.<br>  - `resource_group_name`: The Azure Container Registry resource group name.<br>  - `username_secret_name`: The username secret name stored in Key Vault to use for Azure Container Registry authentication.<br>  - `password_secret_name`: The password secret name stored in Key Vault to use for Azure Container Registry authentication.<br>  - `keyvault_name`: Name of the Key Vault containing the credentials secrets.<br>  - `keyvault_resource_group_name`: Name of the resource group containing the Key Vault. | <pre>object({<br>    name                         = string<br>    resource_group_name          = string<br>    username_secret_name         = string<br>    password_secret_name         = string<br>    keyvault_name                = string<br>    keyvault_resource_group_name = string<br>  })</pre> | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The resource group where to deploy the Azure Container Instance. | `string` | n/a | yes |
| <a name="input_restart_policy"></a> [restart\_policy](#input\_restart\_policy) | The containers restart policy. Can be either `Always`, `Never`, or `OnFailure`. | `string` | `"Always"` | no |
| <a name="input_secure_environment_variables"></a> [secure\_environment\_variables](#input\_secure\_environment\_variables) | Map of sensitive environment variables to set on the Azure Container Instance. | `map(string)` | `{}` | no |
| <a name="input_sequence_number"></a> [sequence\_number](#input\_sequence\_number) | When using count on the module, you should provide a sequence number that will be the storage account name suffix. It must be an integer. | `number` | `1` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The subnet resource IDs for a container group. Changing this forces a new resource to be created. | `list(string)` | n/a | yes |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | Specifies the workload name that will use this resource. This will be used in the resource name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The ID of the Azure Container Instance. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Azure Container Instance. |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | The private IP address of the Azure Container Instance. |

## Resources

| Name | Type |
|------|------|
| [azurerm_container_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group) | resource |
| [azurerm_container_registry.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_registry) | data source |
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_secret.credentials](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lifecycle"></a> [lifecycle](#module\_lifecycle) | ../ccoe.product.tools.lifecycle//module | 0.2.0 |
| <a name="module_names"></a> [names](#module\_names) | ../ccoe.product.naming//module | 0.11.0 |
<!-- END_TF_DOCS -->