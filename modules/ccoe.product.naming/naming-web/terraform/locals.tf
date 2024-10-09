locals {
  private_endpoint_subnets = {
    Lab = {
      name                = "snt-shared-weu1-l-021-1"
      vnet_name           = "vnt-shared-weu1-l-021"
      resource_group_name = "rsg-shared-weu1-l-021"
    }
    Production = {
      name                = "snt-prdcrt-weu1-p-001"
      vnet_name           = "vnt-prdcrt-weu1-p-001"
      resource_group_name = "rsg-prdcrt-weu1-p-002"
    }
  }

  authorized_subnets = {
    Lab = {
      name                = "snt-adoagt-eus1-d-001"
      vnet_name           = "vnt-adoagt-eus1-l-001"
      resource_group_name = "rsg-wwfythupf-eus1-d-021"
      subscription_id     = "0d6d2ddd-df28-49de-bd13-868298d5dbae"
    }
    Production = {
      name                = "snt-agentsall-weu1-p-001-lan"
      vnet_name           = "vnt-agentsall-weu1-p-002"
      resource_group_name = "rsg-agentsall-weu1-p-004"
      subscription_id     = "9edfcf94-ddb7-4d37-a1c8-2461e649c328"
    }
  }
}



