resource "azurerm_container_group" "this" {
  location            = var.location
  name                = module.names.container_instance
  os_type             = "Linux"
  resource_group_name = var.resource_group_name
  restart_policy      = var.restart_policy
  subnet_ids          = var.subnet_ids
  ip_address_type     = "Private"

  dynamic "container" {
    for_each = var.containers

    content {
      cpu    = container.value.cpu
      image  = "${data.azurerm_container_registry.this.login_server}/${container.value.image_name}:${container.value.tag}"
      memory = container.value.memory
      name   = container.value.name

      dynamic "ports" {
        for_each = container.value.ports

        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }

      dynamic "volume" {
        for_each = container.value.volume == null ? [] : [1]

        content {
          mount_path           = container.value.volume.mount_path
          name                 = container.value.volume.name
          share_name           = container.value.volume.share_name
          storage_account_key  = container.value.volume.storage_account_key
          storage_account_name = container.value.volume.storage_account_name
        }
      }

      environment_variables        = var.environment_variables
      secure_environment_variables = var.secure_environment_variables
    }
  }

  image_registry_credential {
    server   = data.azurerm_container_registry.this.login_server
    username = data.azurerm_key_vault_secret.credentials["username"].value
    password = data.azurerm_key_vault_secret.credentials["password"].value
  }

  tags = local.tags
}

module "lifecycle" {
  source     = "../ccoe.product.tools.lifecycle//module?ref=0.2.0"
  depends_on = [azurerm_container_group.this]

  resource_id   = azurerm_container_group.this.id
  environment   = var.environment
  workload_name = var.workload_name
}
