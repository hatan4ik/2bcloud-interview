/**
 * # CCoE Virtual Machine - Linux
 *
 * This module will deploy an Azure Linux Virtual machine compliant with SES Security and MSM controls.
 */
resource "azurerm_network_interface" "nic" {
  name                          = module.names.0.virtual_machine_network_interface
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = local.accelerated_networking
  # From AzureRM 4.0
  # accelerated_networking_enabled= local.accelerated_networking  

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = local.private_ip_allocation
    private_ip_address            = var.private_ip_address
  }

  tags = merge(var.optional_tags, local.default_tags)

  lifecycle {
    ignore_changes = [
      tags["ownerresgroup"],
      tags["owneremail"],
      tags["costcenter"],
      tags["owner"],
      tags["servicecriticality"],
      tags["env"],
      tags["workload"],
      tags["scope"],
      tags["tier"],
    ]
  }
}

resource "azurerm_linux_virtual_machine" "virtual_machine" {
  name                = module.names.0.virtual_machine
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.size
  zone                = var.azure_availability_zone
  custom_data         = var.custom_data
  availability_set_id = var.azure_availability_zone == null ? var.availability_set_id : null

  admin_username                  = var.credentials.user_secret_name
  admin_password                  = "JumbleP@assw0rd"
  disable_password_authentication = var.credentials.disable_password
  encryption_at_host_enabled      = var.encryption_at_host_enabled

  dynamic "admin_ssh_key" {
    # This expression converts the string to a list(string)
    for_each = var.credentials.ssh_public_key[*]
    content {
      username   = var.credentials.user_secret_name
      public_key = var.credentials.ssh_public_key
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage_account_uri
  }

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    name                   = module.names.0.virtual_machine_os_disk
    caching                = var.os_disk_caching
    storage_account_type   = var.os_disk_storage_account_type == null ? local.os_disk_type : var.os_disk_storage_account_type
    disk_encryption_set_id = var.disk_encryption_set_id
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_id == null ? [1] : []
    content {
      publisher = var.source_image_reference != null ? var.source_image_reference.publisher : local.reference_image.publisher
      offer     = var.source_image_reference != null ? var.source_image_reference.offer : local.reference_image.offer
      sku       = var.source_image_reference != null ? var.source_image_reference.sku : local.reference_image.sku
      version   = var.source_image_reference != null ? var.source_image_reference.version : local.reference_image.version
    }
  }

  source_image_id = var.source_image_id

  dynamic "plan" {
    for_each = local.is_lvm ? [1] : []

    content {
      name      = local.plan.name
      product   = local.plan.product
      publisher = local.plan.publisher
    }
  }

  identity {
    type         = var.user_assigned_ids != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.user_assigned_ids
  }

  capacity_reservation_group_id = var.capacity_reservation_group_id

  # Priority and eviction_policy not applicable for 'Production' environment
  priority        = var.environment != "Production" && var.priority != null ? var.priority : null
  eviction_policy = var.environment != "Production" && var.priority == "Spot" && var.eviction_policy != null ? var.eviction_policy : null

  # Azure Update Manager is managed outside of Terraform by the IT Operations.
  # However, there are no values will be changed by IT Operations.
  # Therefore the three parameters below have been implemented.
  # * `bypass_platform_safety_checks_on_user_schedule_enabled`
  # * `patch_assessment_mode`
  # * `patch_mode`

  bypass_platform_safety_checks_on_user_schedule_enabled = var.bypass_platform_safety_checks_on_user_schedule_enabled
  patch_assessment_mode                                  = var.patch_assessment_mode
  patch_mode                                             = var.patch_mode

  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags["ownerresgroup"],
      tags["owneremail"],
      tags["costcenter"],
      tags["owner"],
      tags["servicecriticality"],
      tags["env"],
      tags["workload"],
      tags["scope"],
      tags["tier"]
    ]

    precondition {
      condition = (
        var.environment == "Production" ? var.priority == null && var.eviction_policy == null : true
      )
      error_message = "Priority and eviction_policy not applicable for 'Production' environment."
    }

    precondition {
      condition = (
        var.capacity_reservation_group_id != null ? var.availability_set_id == null && var.azure_availability_zone == null : true
      )
      error_message = "capacity_reservation_group_id cannot be used with `availability_set_id` or 'availability_zone'."
    }
  }
}

resource "null_resource" "reset_password" {
  count = var.credentials.disable_password == false || var.source_image_id == null ? 1 : 0

  triggers = {
    vm_id = azurerm_linux_virtual_machine.virtual_machine.id
  }

  provisioner "local-exec" {
    # Supplying the command this way disables parsing special characters
    command = <<-EOT
      az login --service-principal --username=$ARM_CLIENT_ID --password=$ARM_CLIENT_SECRET --tenant=$ARM_TENANT_ID
      az account set -s $ARM_SUBSCRIPTION_ID
      az vm user update --resource-group ${var.resource_group_name} --name ${azurerm_linux_virtual_machine.virtual_machine.name} --username ${var.credentials.user_secret_name} --password "${var.credentials.password_secret_name}"
    EOT
  }

  depends_on = [azurerm_linux_virtual_machine.virtual_machine]
}

resource "azurerm_backup_protected_vm" "this" {
  count = local.is_backup_enabled ? 1 : 0

  resource_group_name = var.recovery_service_vault.resource_group_name
  recovery_vault_name = var.recovery_service_vault.name
  source_vm_id        = azurerm_linux_virtual_machine.virtual_machine.id
  backup_policy_id    = data.azurerm_backup_policy_vm.backup_policy[0].id

  depends_on = [
    azurerm_linux_virtual_machine.virtual_machine,
  ]
}

module "lifecycle" {
  source     = "../ccoe.product.tools.lifecycle//module?ref=0.2.0"
  depends_on = [azurerm_linux_virtual_machine.virtual_machine]

  resource_id   = azurerm_linux_virtual_machine.virtual_machine.id
  environment   = var.environment
  workload_name = var.workload_name
}
