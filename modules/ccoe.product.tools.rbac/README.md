<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.0.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.0.1 |

## Sample

<details>
<summary>Click to expand</summary>

```hcl
module "role_assignment" {
  # Please update the module's source as indicated below:
  # source = "../ccoe.product.tools.rbac//module?ref=0.2.0"
  source = "../../module"

  role_mapping = [
    {
      role_definition_name = "Key Vault Reader"
      principal_ids        = local.reader_ids
    },
    {
      role_definition_name = "Key Vault Secrets User"
      principal_ids        = local.secretsuser_ids
    }
  ]
  scope_id = module.vault.id
}
```
</details>

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_role_mapping"></a> [role\_mapping](#input\_role\_mapping) | Role and principle id mapping. This block requires the following inputs:<br> - `role_definition_name`: Role Name i.e. Key Vault Administrator <br> - `principal_ids`: List of ids. | <pre>list(object({<br>    role_definition_name = string<br>    principal_ids        = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_scope_id"></a> [scope\_id](#input\_scope\_id) | The Id of the scope where the role should be assigned. | `string` | n/a | yes |

## Outputs

No outputs.

## Resources

| Name | Type |
|------|------|
| [azurerm_role_assignment.role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Modules

No modules.
<!-- END_TF_DOCS -->