resource_group_name = "rsg-nathanels-eus1-l-001"
location            = "eastus"
resource_prefix    = "myapp"

vnet_address_space = "10.0.0.0/16"

kubernetes_version = "1.30.5"
node_count         = 1
vm_size            = "Standard_D2_v2"

replicas      = 1
app_namespace = "myapp"

target_namespaces = ["myapp", "default"]

subnets = {
  aks = {
    name           = "aks-subnet"
    address_prefix = "10.0.1.0/24"
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
  },
  jenkins = {
    name           = "jenkins-subnet"
    address_prefix = "10.0.2.0/24"
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
  },
  acr = {
    name           = "acr-subnet"
    address_prefix = "10.0.3.0/24"
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
  }
  # Add more subnets as needed
}

nsgs = {
  aks = {
    name = "aks-nsg"
    rules = [
      {
        name                       = "allow-http-traffic"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      ]
    },
  acr = {
    name = "acr-nsg"
    rules = [
      {
        name                       = "allow-ac-traffic"
        priority                   = 102
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  jenkins = {
    name = "jenkins-nsg"
    rules = [
      {
        name                       = "allow-http-traffic"
        priority                   = 103
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  }
}

route_table_ids = {
  "aks"     = "route-table-id-for-aks"
  "jenkins" = "route-table-id-for-jenkins"
  "acr"     = "route-table-id-for-acr"
}

#### SES LAB Subscription
subscription_id = "5d982ebd-0020-42c8-8137-c73e378bf0ee"
tenant_id = "46413989-42dc-4b1e-b8aa-e0a855d29515"

## Private Nathanel Subscription
#subscription_id = "1fd5b2b6-8e57-4cfe-95f8-176a7a8d1abf"
#tenant_id = "9fe4b66a-8e9f-4e8c-a935-b81c51c70467"