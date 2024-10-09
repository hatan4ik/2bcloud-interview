locals {
  map_accelerated_networking = {
    Lab         = false
    Test        = false
    Development = false
    Production  = true
    Global      = true
  }
  accelerated_networking = local.map_accelerated_networking[var.environment]
  map_os_disk_type = {
    Lab         = "StandardSSD_LRS",
    Test        = "StandardSSD_LRS",
    Development = "StandardSSD_LRS",
    Production  = "Premium_LRS",
    Global      = "Premium_LRS",
  }
  os_disk_type = local.map_os_disk_type[var.environment]

  map_reference_image = {
    CentOS8 = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "8_4"
      version   = "latest"
    },
    CentOS7 = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "7_9"
      version   = "latest"
    },
    CentOS8-LVM = {
      publisher = "procomputers"
      offer     = "centos-8-lvm"
      sku       = "centos-8-lvm"
      version   = "latest"
    },
    CentOS7-LVM = {
      publisher = "procomputers"
      offer     = "centos-7-lvm"
      sku       = "centos-7-lvm"
      version   = "latest"
    },
    Debian9 = {
      publisher = "credativ"
      offer     = "Debian"
      sku       = "9-backports"
      version   = "latest"
    },
    Debian10 = {
      publisher = "Debian"
      offer     = "debian-10"
      sku       = "10"
      version   = "latest"
    },
    Ubuntu1804 = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }
    Ubuntu2004 = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts"
      version   = "latest"
    }
    Ubuntu2204 = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      version   = "latest"
    }
    RedHat8 = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "8_4"
      version   = "latest"
    },
    Debian11 = {
      publisher = "Debian"
      offer     = "debian-11"
      sku       = "11"
      version   = "latest"
    },
  }

  reference_image = local.map_reference_image[var.distribution]

  default_tags = {
    CCoEProdVersion      = "VMLv3.1.0"
    OSUpdateDayOfWeekend = var.tag_OSUpdateDayOfWeekend
    OSUpdateSkip         = var.tag_OSUpdateSkip
    OSUpdateDisabled     = var.tag_OSUpdateDisabled
    OSUpdateException    = var.tag_OSUpdateException
  }
  tags = merge(var.optional_tags, local.default_tags)

  private_ip_allocation = var.private_ip_address == null ? "Dynamic" : "Static"
  is_backup_enabled     = var.recovery_service_vault != null || var.environment == "Production" || var.environment == "Global" ? true : false

  # LVM version details
  is_lvm = var.distribution == "CentOS7-LVM" || var.distribution == "CentOS8-LVM" ? true : false

  plan_reference = {
    CentOS7-LVM = {
      name      = "centos-7-lvm",
      product   = "centos-7-lvm",
      publisher = "procomputers"
    },
    CentOS8-LVM = {
      name      = "centos-8-lvm",
      product   = "centos-8-lvm",
      publisher = "procomputers"
    }
  }

  plan = local.is_lvm ? local.plan_reference[var.distribution] : null
}
