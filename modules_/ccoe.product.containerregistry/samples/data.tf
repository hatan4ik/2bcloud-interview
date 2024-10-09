data "azuread_service_principal" "workload_service_principal" {
  # Service principals information can be fetched from it's application_id or object_id or display_name property.
  # See https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal
  display_name = "sp-verifyprd-d-01"
}

data "azurerm_subnet" "spoke" {
  name                 = "snt-verifyprd-eus1-d-001"
  resource_group_name  = "rsg-verifyprd-eus1-d-002"
  virtual_network_name = "vnt-verifyprd-eus1-d-001"
}

data "azurerm_client_config" "current" {}
