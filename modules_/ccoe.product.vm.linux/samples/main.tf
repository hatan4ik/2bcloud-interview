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
