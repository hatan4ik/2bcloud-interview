module "registry" {
  source = "../ccoe.product.containerregistry//module?ref=4.1.0"

  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  workload_name       = random_string.workload_name.result

  image_pull_service_principal_ids = [data.azurerm_client_config.current.object_id]

  depends_on = [
    azurerm_resource_group.this,
  ]
}

resource "null_resource" "image_build_push" {
  depends_on = [module.registry]

  provisioner "local-exec" {
    command = "${path.module}/../test/helpers/registry/files/docker-push-image-to-acr.ps1 -RegistryName ${module.registry.name}"

    interpreter = ["pwsh", "-Command"]
  }
}
