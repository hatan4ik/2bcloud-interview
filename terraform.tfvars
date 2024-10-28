resource_group_name = "Nathanel-Candidate"
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