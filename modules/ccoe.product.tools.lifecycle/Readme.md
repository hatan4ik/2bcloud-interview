# Module `ccoe.product.tools.lifecycle`

Core Version Constraints:
* `>=0.13`

Provider Requirements:
* **null (`hashicorp/null`):** `~>3.1.0`

## Sample
```hcl-terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.41.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "=3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  location = "west europe"
  name     = "rsg-workload-weu1-l-001"
}

module "product_lifecycle" {
  depends_on = [azurerm_resource_group.this]
  source     = "../ccoe.product.tools.lifecycle//module?ref=0.3.0"

  resource_id   = azurerm_resource_group.this.id
  environment   = "Production"
  workload_name = "workload"
}
```

## Input Variables
* `environment` (required): The environment in which the apply/destroy is happening.
* `resource_id` (required): The ID of the resource being created/destroyed.
* `workload_name` (required): The workload name.

## Managed Resources
* `null_resource.lifecycle_event` from `null`

