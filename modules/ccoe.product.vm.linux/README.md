<!-- BEGIN_TF_DOCS -->
# CCoE Virtual Machine - Linux

This module will deploy an Azure Linux Virtual machine compliant with SES Security and MSM controls.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >=1.4.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.0.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >=0.7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.0.1 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Sample

<details>
<summary>Click to expand</summary>

```hcl
module "disk_encryption" {
  source = "../ccoe.product.tools.diskencryptionset//module?ref=0.4.0"

  workload_name       = local.workload_name
  resource_group_name = azurerm_resource_group.this.name
  keyvault_id         = module.keyvault.id
  location            = local.location
  optional_tags       = azurerm_resource_group.this.tags
  environment         = local.environment

  depends_on = [module.credentials]
}

data "azuread_group" "this" {
  display_name = "az_sub-oa-d-verifyprd-01_contributors"
}

module "availability_set" {
  source = "../ccoe.product.availabilityset//module?ref=1.2.0"

  resource_group_name = azurerm_resource_group.this.name
  environment         = local.environment
  location            = local.location
  workload_name       = random_string.workload_name.result
}

module "certified_vm" {
  # Please update the module's source as indicated below:
  # source = "../ccoe.product.vm.linux//module?ref=3.1.0"
  source = "../module"

  location                   = azurerm_resource_group.this.location
  environment                = local.environment
  workload_name              = random_string.workload_name.result
  size                       = "Standard_D4s_v3"
  disk_encryption_set_id     = module.disk_encryption.id
  custom_data                = filebase64("./cloud-init.sh")
  user_assigned_ids          = [azurerm_user_assigned_identity.vm_mi.id, azurerm_user_assigned_identity.vm_mi_2.id]
  distribution               = "CentOS8"
  encryption_at_host_enabled = false
  #availability_set_id    = module.availability_set.id  #Having conflict with `capacity_reservation_group_id`
  #azure_availability_zone = 1 # Having conflict with `availability_set_id`
  capacity_reservation_group_id = azurerm_capacity_reservation_group.this.id

  data_disk_config = {
    disk1 = {
      size                 = 50,
      storage_account_type = "Standard_LRS"
    },
  }

  credentials = {
    user_secret_name = module.credentials.secret_user

    # Here we can use either SSH public key or a password, not both.
    # For SSH public key, only the ssh-rsa type is accepted, minimum 2048 bits.
    #    ssh_public_key   = tls_private_key.sample_ssh.public_key_openssh
    disable_password     = false
    password_secret_name = module.credentials.secret_password
  }

  storage_account_uri    = module.storage.primary_blob_endpoint
  resource_group_name    = azurerm_resource_group.this.name
  subnet_id              = data.azurerm_subnet.spoke.id
  recovery_service_vault = local.rvt

  administrator_role_object_ids = [data.azuread_group.this.object_id]

  # Optional recovery service vault for VM backup:
  # recovery_service_vault = {
  #   name = RECOVERY_VAULT_NAME
  #   resource_group_name = RECOVERY_VAULT_RG_NAME
  # }

  bypass_platform_safety_checks_on_user_schedule_enabled = false
  patch_assessment_mode                                  = "ImageDefault"
  patch_mode                                             = "ImageDefault"

  optional_tags = azurerm_resource_group.this.tags

  # The tags below are mandatory for VMs, in case you don't set them up, default values will be taken in place.
  #  tag_OSUpdateDayOfWeekend = "Saturday"
  #  tag_OSUpdateSkip         = false
  #  tag_OSUpdateDisabled     = false
  #  tag_OSUpdateException    = false

  #Optional backup policy name for Linux VM.
  # backup_policy_name = "CustomRSVBackupPolicy"

  ##Spot instance not available for 'Production' environment
  #priority        = "Spot"
  #eviction_policy = "Delete"

  depends_on = [module.disk_encryption, azurerm_capacity_reservation.this]
}
```
### For a complete deployment example, please check [sample folder](/samples).
</details>

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_administrator_role_object_ids"></a> [administrator\_role\_object\_ids](#input\_administrator\_role\_object\_ids) | List of object IDs to be added with Virtual Machine Administrator role on Linux VM. | `list(string)` | `[]` | no |
| <a name="input_availability_set_id"></a> [availability\_set\_id](#input\_availability\_set\_id) | Specifies the ID of the Availability Set in which the Virtual Machine should exist. This input having conflict with availability\_zones and changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_azure_availability_zone"></a> [azure\_availability\_zone](#input\_azure\_availability\_zone) | Set virtual machine availability zones number. Allowed value is a 1, 2 or 3. | `number` | `null` | no |
| <a name="input_backup_policy_name"></a> [backup\_policy\_name](#input\_backup\_policy\_name) | The options to set the name of the existing backup policy in place in the Recovery Service Vault for the virtual machine. If no value is provided value will be set to `DefaultPolicy`. | `string` | `"DefaultPolicy"` | no |
| <a name="input_bypass_platform_safety_checks_on_user_schedule_enabled"></a> [bypass\_platform\_safety\_checks\_on\_user\_schedule\_enabled](#input\_bypass\_platform\_safety\_checks\_on\_user\_schedule\_enabled) | Specifies whether to skip platform scheduled patching when a user schedule is associated with the VM.<br> This value can be set `true` only when `path_mode` is set to `AutomaticByplatform`. <br> Please check the supported list from this link. https://aka.ms/VMGuestPatchingCompatibility. <br> Default value is `false`. | `bool` | `false` | no |
| <a name="input_capacity_reservation_group_id"></a> [capacity\_reservation\_group\_id](#input\_capacity\_reservation\_group\_id) | Specifies the ID of the Capacity Reservation Group which the Virtual Machine should be allocated to. | `string` | `null` | no |
| <a name="input_classic_contributor_role_object_ids"></a> [classic\_contributor\_role\_object\_ids](#input\_classic\_contributor\_role\_object\_ids) | List of object IDs to be added with Classic Virtual Machine Contributor role on Linux VM. | `list(string)` | `[]` | no |
| <a name="input_contributor_role_object_ids"></a> [contributor\_role\_object\_ids](#input\_contributor\_role\_object\_ids) | List of object IDs to be added with Virtual Machine Contributor role on Linux VM. | `list(string)` | `[]` | no |
| <a name="input_credentials"></a> [credentials](#input\_credentials) | The names used for VMs secrets inside Key Vault. This block requires the following inputs:<br>- `user_secret_name`: The user name secret.<br>Either:<br>- `password_secret_name`: The password secret.<br>or:<br>- `ssh_public_key`: The SSH key to allow. Only ssh-rsa keys are accepted.<br>Is the password used or not. In case ssh\_public\_key is used, this should be set to 'true'.<br>- `disable_password`: True or false. | <pre>object({<br>    user_secret_name     = string<br>    password_secret_name = optional(string)<br>    ssh_public_key       = optional(string)<br>    disable_password     = bool<br>  })</pre> | n/a | yes |
| <a name="input_custom_data"></a> [custom\_data](#input\_custom\_data) | Custom Data which should be used for this Virtual Machine as cloud-init. | `string` | `null` | no |
| <a name="input_data_disk_config"></a> [data\_disk\_config](#input\_data\_disk\_config) | Specifies the size of the data disks to create in gigabytes. eg. {disk1 = 50, disk2 = 100} | <pre>map(object({<br>    size                 = number<br>    storage_account_type = string<br>  }))</pre> | `{}` | no |
| <a name="input_disk_encryption_set_id"></a> [disk\_encryption\_set\_id](#input\_disk\_encryption\_set\_id) | The disk encryption set id that will be used for Server Side Encryption of Linux VM. | `string` | n/a | yes |
| <a name="input_distribution"></a> [distribution](#input\_distribution) | The linux distribution used on this machine. Allowed values are `CentOS7`, `CentOS8`, `Debian9`, `Debian10`, `Debian11`, `Ubuntu1804`, `Ubuntu2004` and `Ubuntu2204`. | `string` | `"CentOS7"` | no |
| <a name="input_encryption_at_host_enabled"></a> [encryption\_at\_host\_enabled](#input\_encryption\_at\_host\_enabled) | Should all of the disks (including the temp disk) attached to this Virtual Machine be encrypted by enabling Encryption at Host? | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Specifies the name of the environment where this resource is deployed. This will be used in the resource name. Valid values are 'Lab', 'Test', 'Development' and 'Production'. | `string` | n/a | yes |
| <a name="input_eviction_policy"></a> [eviction\_policy](#input\_eviction\_policy) | Specifies what should happen when the Virtual Machine is evicted for price reasons when using a Spot instance. Possible values are `Deallocate` and `Delete`. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive). | `string` | n/a | yes |
| <a name="input_optional_tags"></a> [optional\_tags](#input\_optional\_tags) | Optional tags for the Linux Virtual Machine. For more details, please check the Optional tags and values in the [Tagging convention wiki page](https://dev.azure.com/SES-CCoE/CCoE/_wiki/wikis/SES%20CCoE%20Wiki/862/Tagging-Convention?anchor=optional-tags-and-values). | `map(string)` | `{}` | no |
| <a name="input_os_disk_caching"></a> [os\_disk\_caching](#input\_os\_disk\_caching) | The Type of Caching which should be used for the Internal OS Disk. Possible values are 'None', 'ReadOnly' and 'ReadWrite'. | `string` | `"ReadWrite"` | no |
| <a name="input_os_disk_storage_account_type"></a> [os\_disk\_storage\_account\_type](#input\_os\_disk\_storage\_account\_type) | The Type of Storage Account which should back this the Internal OS Disk. Possible values are 'Standard\_LRS', 'StandardSSD\_LRS', 'Premium\_LRS', 'StandardSSD\_ZRS' and 'Premium\_ZRS'. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_patch_assessment_mode"></a> [patch\_assessment\_mode](#input\_patch\_assessment\_mode) | Specifies the mode of VM Guest Patching for the Virtual Machine. Possible values are `AutomaticByPlatform` or `ImageDefault`. Defaults to `ImageDefault`. | `string` | `"ImageDefault"` | no |
| <a name="input_patch_mode"></a> [patch\_mode](#input\_patch\_mode) | Specifies the mode of in-guest patching to this Linux Virtual Machine.<br> Possible values are `AutomaticByPlatform` and `ImageDefault`. Defaults to `ImageDefault`. | `string` | `"ImageDefault"` | no |
| <a name="input_priority"></a> [priority](#input\_priority) | Specifies the priority of this Virtual Machine. Possible values are `Regular` and `Spot`. | `string` | `null` | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | The Static IP Address which should be used (IP allocation will be dynamic if not set). | `string` | `null` | no |
| <a name="input_recovery_service_vault"></a> [recovery\_service\_vault](#input\_recovery\_service\_vault) | The recovery options for the recovery service vault for the backup. If not null, this block requires the following inputs: <br>  - `name`: The name of the service vault <br>  - `resource_group_name`: The name of the resource group containing the service vault | <pre>object({<br>    resource_group_name = string<br>    name                = string<br>  })</pre> | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The resource group to deploy the VM. | `string` | n/a | yes |
| <a name="input_sequence_number"></a> [sequence\_number](#input\_sequence\_number) | When using count on the module, you should provide a sequence number that will be the Linux VM name suffix. It must be an integer. | `number` | `1` | no |
| <a name="input_size"></a> [size](#input\_size) | The size of this machine. Allowed values are like `Standard_D2s_v3`, `Standard_D4s_v3`, `Standard_D8s_v3` etc. Find out more on the valid VM sizes in each region at https://aka.ms/azure-regionservices. | `string` | `"Standard_D2s_v3"` | no |
| <a name="input_source_image_id"></a> [source\_image\_id](#input\_source\_image\_id) | The ID of an Image which each Virtual Machine in this Linux VM should be based on. | `string` | `null` | no |
| <a name="input_source_image_reference"></a> [source\_image\_reference](#input\_source\_image\_reference) | Source image for the Linux VM. This block requires the following inputs:<br>  - `publisher`: The the publisher of the image used to create the virtual machine.<br>  - `offer`: The offer of the image used to create the virtual machine. <br>  - `sku`: The SKU of the image used to create the virtual machine. <br>  - `version`: The version of the image used to create the virtual machine. Changing this forces a new resource to be created. | <pre>object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = string<br>  })</pre> | `null` | no |
| <a name="input_storage_account_uri"></a> [storage\_account\_uri](#input\_storage\_account\_uri) | The uri for the storage account used to store boot diagnostics. | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The subnet ID where the VM will be deployed. | `string` | n/a | yes |
| <a name="input_tag_OSUpdateDayOfWeekend"></a> [tag\_OSUpdateDayOfWeekend](#input\_tag\_OSUpdateDayOfWeekend) | The day in which update will be planned. Allowed values are `Saturday` and `Sunday`. | `string` | `"Saturday"` | no |
| <a name="input_tag_OSUpdateDisabled"></a> [tag\_OSUpdateDisabled](#input\_tag\_OSUpdateDisabled) | This tag's value must be set if you want or not to disable the VM's regular update. | `bool` | `false` | no |
| <a name="input_tag_OSUpdateException"></a> [tag\_OSUpdateException](#input\_tag\_OSUpdateException) | This tag's value must be set if the VM is `excluded`q from default Deployment Groups. | `bool` | `false` | no |
| <a name="input_tag_OSUpdateSkip"></a> [tag\_OSUpdateSkip](#input\_tag\_OSUpdateSkip) | This tag's value must be set if you want or not to skip the VM's update. If `true`, next update circle the VM will be skipped from the deployment query or not. | `bool` | `false` | no |
| <a name="input_user_assigned_ids"></a> [user\_assigned\_ids](#input\_user\_assigned\_ids) | List of User Assigned Managed Identity IDs to be assigned to this Linux Virtual Machine. <br> Kindly note that module will add the System Assigned Identities by default. | `list(string)` | `null` | no |
| <a name="input_user_role_object_ids"></a> [user\_role\_object\_ids](#input\_user\_role\_object\_ids) | List of object IDs to be added with Virtual Machine User Login role on Linux VM. | `list(string)` | `[]` | no |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | Specifies the workload name that will use this resource. This will be used in the resource name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data_disk_name"></a> [data\_disk\_name](#output\_data\_disk\_name) | The name of the data disks of the virtual machine. |
| <a name="output_identity_ids"></a> [identity\_ids](#output\_identity\_ids) | Identity ids associated with this Virtual machine |
| <a name="output_network_watcher_extension_name"></a> [network\_watcher\_extension\_name](#output\_network\_watcher\_extension\_name) | The name of the network watcher extension of the virtual machine. |
| <a name="output_nic_id"></a> [nic\_id](#output\_nic\_id) | The name of the network interface card of the virtual machine. |
| <a name="output_nic_name"></a> [nic\_name](#output\_nic\_name) | The name of the network interface card of the virtual machine. |
| <a name="output_os_disk_name"></a> [os\_disk\_name](#output\_os\_disk\_name) | The name of the OS disk of the virtual machine. |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | The private IP of the virtual machine. |
| <a name="output_user_assigned_ids"></a> [user\_assigned\_ids](#output\_user\_assigned\_ids) | The list of user assigned managed identities for the Linux VM. |
| <a name="output_virtual_machine_id"></a> [virtual\_machine\_id](#output\_virtual\_machine\_id) | The ID of the virtual machine. |
| <a name="output_virtual_machine_name"></a> [virtual\_machine\_name](#output\_virtual\_machine\_name) | The name of the virtual machine. |

## Resources

| Name | Type |
|------|------|
| [azurerm_backup_protected_vm.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_protected_vm) | resource |
| [azurerm_linux_virtual_machine.virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_managed_disk.data_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_virtual_machine_data_disk_attachment.attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension.network_watcher](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [null_resource.reset_password](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [azurerm_backup_policy_vm.backup_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/backup_policy_vm) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_data_disk_names"></a> [data\_disk\_names](#module\_data\_disk\_names) | ../ccoe.product.naming//module | 0.9.0 |
| <a name="module_lifecycle"></a> [lifecycle](#module\_lifecycle) | ../ccoe.product.tools.lifecycle//module | 0.2.0 |
| <a name="module_names"></a> [names](#module\_names) | ../ccoe.product.naming//module | 0.9.0 |
| <a name="module_role_assignment"></a> [role\_assignment](#module\_role\_assignment) | ../ccoe.product.tools.rbac//module | 0.2.0 |
<!-- END_TF_DOCS -->