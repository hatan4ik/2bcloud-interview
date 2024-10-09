module "aci" {
  //  source = "../ccoe.product.containerinstance//module?ref=2.3.0"
  source = "../module"

  environment         = local.environment
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workload_name       = random_string.workload_name.result
  restart_policy      = "OnFailure"

  secure_environment_variables = {
    "secret_name" : "****"
  }

  environment_variables = {
    "name" : "value"
  }

  registry = {
    name                         = module.registry.name
    resource_group_name          = azurerm_resource_group.this.name
    username_secret_name         = "spid-sub-oa-d-verifyprd-01"
    password_secret_name         = "spsecret-sub-oa-d-verifyprd-01"
    keyvault_name                = data.azurerm_key_vault.sp_vault.name
    keyvault_resource_group_name = data.azurerm_key_vault.sp_vault.resource_group_name
  }

  containers = [
    {
      name       = "api"
      image_name = "docker-test"
      tag        = "1.0.0"
      cpu        = 1
      memory     = 1
      ports = [
        {
          port     = 3000,
          protocol = "TCP"
        }
      ]
      volume = null
    }
  ]

  subnet_ids = [data.azurerm_subnet.aci.id]

  optional_tags = azurerm_resource_group.this.tags

  depends_on = [null_resource.image_build_push]
}
