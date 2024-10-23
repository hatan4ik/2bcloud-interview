resource_group_name = "Nathanel-Candidate"
vnet_name           = "my-vnet"
vnet_address_space  = "10.0.0.0/16"
subnets = {
  jenkins = {
    name              = "jenkins-subnet"
    address_prefix    = "10.0.1.0/24"
    service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
  },
  aks = {
    name              = "aks-subnet"
    address_prefix    = "10.0.2.0/24"
    service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Storage"]
  },
  acr = {
    name              = "acr-subnet"
    address_prefix    = "10.0.3.0/24"
    service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
  }
}
nsgs = {
  jenkins = {
    name = "jenkins-nsg"
    rules = [
      {
        name                       = "allow-ssh"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "allow-http"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  aks = {
    name = "aks-nsg"
    rules = [
      {
        name                       = "allow-http"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "allow-https"
        priority                   = 110
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
  acr = {
    name = "acr-nsg"
    rules = [
      {
        name                       = "allow_acr"
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  }
}
kubernetes_version  = "1.30.4"
node_count          = 1
vm_size             = "Standard_DS2_v2"
nginx_ingress_image = "k8s.gcr.io/ingress-nginx/controller:v1.2.1"
location            = "westeurope"