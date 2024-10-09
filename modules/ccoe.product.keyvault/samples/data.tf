data "azurerm_client_config" "current" {}

data "azurerm_subnet" "spoke" {
  name                 = "snt-verifyprd-eus1-d-001"
  resource_group_name  = "rsg-verifyprd-eus1-d-002"
  virtual_network_name = "vnt-verifyprd-eus1-d-001"
}
