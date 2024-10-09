## -------------------------
#  Managed Prometheus
## -------------------------
resource "azurerm_monitor_workspace" "amw" {
  name                = "amw-${random_string.workload_name.result}-${local.location_identifier}-${local.environment_identifier}-002"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  public_network_access_enabled = true
}

## -------------------------
#  Managed Prometheus & Grafana connection
## -------------------------
resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                = "MSProm-${azurerm_resource_group.this.location}-${module.aks.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  kind                = "Linux"
  description         = "Data ingestion into an Azure Monitor workspace is managed via Data Collection Endpoints."

  public_network_access_enabled = true
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                        = "MSProm-${azurerm_resource_group.this.location}-${module.aks.name}"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id
  kind                        = "Linux"

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.amw.id
      name               = "MonitoringAccount1"
    }

    azure_monitor_metrics {
      name = "example-destination-metrics"
    }

  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["example-destination-metrics"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  description = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"
  depends_on = [
    azurerm_monitor_data_collection_endpoint.dce
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                    = "MSProm-${azurerm_resource_group.this.location}-${module.aks.name}"
  target_resource_id      = module.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id

  description = "Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster, in ${module.aks.name}."

  depends_on = [
    azurerm_monitor_data_collection_rule.dcr
  ]
}

## -------------------------
#  Managed Grafana
## -------------------------
resource "azurerm_dashboard_grafana" "grafana" {
  name                              = "grf-sdlf-eus1-d-002"
  resource_group_name               = azurerm_resource_group.this.name
  location                          = azurerm_resource_group.this.location
  sku                               = "Standard"
  api_key_enabled                   = false
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.amw.id
  }
}



## -------------------------
#  Role Assignments
## -------------------------
resource "azurerm_role_assignment" "monitoring_readers" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
}

resource "azurerm_role_assignment" "datareaderrole" {
  scope              = azurerm_monitor_workspace.amw.id
  role_definition_id = "/subscriptions/${split("/", azurerm_monitor_workspace.amw.id)[2]}/providers/Microsoft.Authorization/roleDefinitions/b0d8363b-8ddd-447d-831f-62ca05bff136"
  principal_id       = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}