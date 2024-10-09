module "acr" {
  # source = "../ccoe.product.containerregistry//module?ref=4.2.0"
  source = "../module"

  environment              = local.environment
  location                 = local.location
  resource_group_name      = azurerm_resource_group.rg.name
  workload_name            = random_string.workload_name.result
  georeplication_locations = ["northeurope", "westeurope"]

  # Public IP range for ADO services to access private ACR.
  # This is only required only if user trying to push image but not using separate ADO agents.
  #authorized_ips_or_cidr_blocks = ["52.168.115.0/24"]

  # Here you can provide a list of object ids that need to be able to pull images from Azure Container Registry
  # In a DevOps team context, a service principal is created by the platform team you may want to use it (or not)
  # You can also provide the object_id of a service principal (Managed Identity for example) created within your Terraform
  image_pull_service_principal_ids = [
    data.azuread_service_principal.workload_service_principal.id
  ]

  image_push_service_principal_ids = [
    data.azuread_service_principal.workload_service_principal.id
  ]

  optional_tags = {
    supportResGroup = azurerm_resource_group.rg.name
  }

  #If you want to deploy private endpoint for ACR private_endpoint_subnet_id should be provided. This will be the id of the subnet that private endpoint will use.
  private_endpoint = {
    "my_pep" = {
      subnet_id = data.azurerm_subnet.spoke.id
      ip_configuration = [
        {
          member_name        = "registry"
          private_ip_address = "10.57.50.61"
        },
        #When static IP is used in ACR private endpoint, a second IP configuration must be added, with the member_name
        # "registry_data_<ACR location>".
        {
          member_name        = "registry_data_eastus"
          private_ip_address = "10.57.50.62"
        },
        #When static IP is used in ACR private endpoint and georeplivation is enabled, a second IP configuration
        # 3 IP additional configurations should be present: "registry_data_<ACR location>", "registry_data_<first ACR georeplication location>"
        # and "registry_data_<second ACR georeplication location>".
        {
          member_name        = "registry_data_westeurope"
          private_ip_address = "10.57.50.63"
        },
        {
          member_name        = "registry_data_northeurope"
          private_ip_address = "10.57.50.64"
        },
      ]
    }
  }
}

resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = "${path.module}/app1/docker-push-image-to-acr.ps1 -RegistryName ${module.acr.name}"

    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [module.acr]
}
