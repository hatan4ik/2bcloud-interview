resource_group_name = "Nathanel-Candidate"
resource_prefix    = "myapp"

vnet_address_space = "10.0.0.0/16"

kubernetes_version = "1.3.0"
node_count         = 1
vm_size            = "Standard_D2_v2"

replicas      = 1
app_namespace = "myapp"

target_namespaces = ["myapp", "monitoring"]

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
  aks-nsg = {
    name = "aks-nsg"
    rules = [
      {
        name                       = "allow-http-traffic"
        priority                   = 100
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
  acr-nsg = {
    name = "acr-nsg"
    rules = [
      {
        name                       = "allow-ac-traffic"
        priority                   = 100
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
  jenkins-nsg = {
    name = "jenkins-nsg"
    rules = [
      {
        name                       = "allow-http-traffic"
        priority                   = 100
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
