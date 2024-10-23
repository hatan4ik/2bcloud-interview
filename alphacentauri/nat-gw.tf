# # Create a public IP for the NAT gateway
# resource "azurerm_public_ip" "nat_ip" {
#   name                = "nat-gateway-ip"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Create the NAT gateway
# resource "azurerm_nat_gateway" "nat_gateway" {
#   name                = "nat-gateway"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name
#   sku_name            = "Standard"

#   public_ip_address {
#     id = azurerm_public_ip.nat_ip.id
#   }
# }

# # Associate the NAT gateway with the subnets
# resource "azurerm_subnet_nat_gateway_association" "nat_gateway_assoc" {
#   for_each        = azurerm_subnet.subnets
#   subnet_id       = each.value.id
#   nat_gateway_id  = azurerm_nat_gateway.nat_gateway.id
# }