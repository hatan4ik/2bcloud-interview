<!-- BEGIN_TF_DOCS -->

## Sample
```hcl-terraform
module "names" {
source        = "../ccoe.product.naming//module?ref=0.12.0"
environment   = "Production"
location      = "westeurope"
workload_name = "myapp"
}
```
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | The environment where to deploy the resource. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Specifies the supported Azure location of the resource. Changing this forces a new resource to be created. Valid options for location are: westeurope, West Europe, eastus, East US, eastus2, East US2, global, Global, centralus, Central US, northeurope or North Europe (case and whitespaces insensitive). | `string` | n/a | yes |
| <a name="input_private_endpoint_resource_name"></a> [private\_endpoint\_resource\_name](#input\_private\_endpoint\_resource\_name) | The name of the Azure resource involved in private endpoint. | `string` | `""` | no |
| <a name="input_private_endpoint_subnet_name"></a> [private\_endpoint\_subnet\_name](#input\_private\_endpoint\_subnet\_name) | The name of the subnet of the private endpoint. | `string` | `""` | no |
| <a name="input_sequence_number"></a> [sequence\_number](#input\_sequence\_number) | When using count on the module, you should provide a sequence number that will be used in the Azure Resource name. It must be an integer between 1 and 999. | `number` | `1` | no |
| <a name="input_sub_resource_sequence_number"></a> [sub\_resource\_sequence\_number](#input\_sub\_resource\_sequence\_number) | When you have a subresource to create (vm disk, vm extension...), you should provide a sub resource sequence number that will be used in the Azure sub Resource name. It must be an integer between 1 and 99. | `number` | `1` | no |
| <a name="input_subscription_name"></a> [subscription\_name](#input\_subscription\_name) | Used for Resource Health and Service Health Alerts. | `string` | `""` | no |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | Free text used for some resources which supports suffix : subscription, subnet, network\_security\_group, service\|resource health alerts, action groups. The value will be truncated according to the naming convention. | `string` | `""` | no |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | Specifies the workload name that will use this resource. This will be used in the resource name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_action_group"></a> [action\_group](#output\_action\_group) | Name for `action_group` resource. |
| <a name="output_allow_network_security_group"></a> [allow\_network\_security\_group](#output\_allow\_network\_security\_group) | Name for `allow_network_security_group` resource. |
| <a name="output_analytics_service"></a> [analytics\_service](#output\_analytics\_service) | Name for `analytics_service` resource. |
| <a name="output_api_management"></a> [api\_management](#output\_api\_management) | Name for `api_management` resource. |
| <a name="output_app_configuration"></a> [app\_configuration](#output\_app\_configuration) | Name for `app_configuration` resource. |
| <a name="output_app_service"></a> [app\_service](#output\_app\_service) | Name for `app_service` resource. |
| <a name="output_app_service_certificate"></a> [app\_service\_certificate](#output\_app\_service\_certificate) | Name for `app_service_certificate` resource. |
| <a name="output_app_service_domain"></a> [app\_service\_domain](#output\_app\_service\_domain) | Name for `app_service_domain` resource. |
| <a name="output_app_service_environment"></a> [app\_service\_environment](#output\_app\_service\_environment) | Name for `app_service_environment` resource. |
| <a name="output_app_service_plan"></a> [app\_service\_plan](#output\_app\_service\_plan) | Name for `app_service_plan` resource. |
| <a name="output_application_gateway"></a> [application\_gateway](#output\_application\_gateway) | Name for `application_gateway` resource. |
| <a name="output_application_insight"></a> [application\_insight](#output\_application\_insight) | Name for `application_insight` resource. |
| <a name="output_application_security_group"></a> [application\_security\_group](#output\_application\_security\_group) | Name for `application_security_group` resource. |
| <a name="output_availability_set"></a> [availability\_set](#output\_availability\_set) | Name for `availability_set` resource. |
| <a name="output_azure_cache_for_redis"></a> [azure\_cache\_for\_redis](#output\_azure\_cache\_for\_redis) | Name for `azure_cache_for_redis` resource. |
| <a name="output_azure_data_explorer_cluster"></a> [azure\_data\_explorer\_cluster](#output\_azure\_data\_explorer\_cluster) | Name for `azure_data_explorer_cluster` resource. |
| <a name="output_azure_database_migration_service"></a> [azure\_database\_migration\_service](#output\_azure\_database\_migration\_service) | Name for `azure_database_migration_service` resource. |
| <a name="output_azure_db_for_mariadb_server"></a> [azure\_db\_for\_mariadb\_server](#output\_azure\_db\_for\_mariadb\_server) | Name for `azure_db_for_mariadb_server` resource. |
| <a name="output_azure_db_for_mysql"></a> [azure\_db\_for\_mysql](#output\_azure\_db\_for\_mysql) | Name for `azure_db_for_mysql` resource. |
| <a name="output_azure_db_for_postgresql"></a> [azure\_db\_for\_postgresql](#output\_azure\_db\_for\_postgresql) | Name for `azure_db_for_postgresql` resource. |
| <a name="output_azure_firewall"></a> [azure\_firewall](#output\_azure\_firewall) | Name for `azure_firewall` resource. |
| <a name="output_azure_monitor_workspace"></a> [azure\_monitor\_workspace](#output\_azure\_monitor\_workspace) | Name for `azure_monitor_workspace` resource. |
| <a name="output_azure_spring_cloud"></a> [azure\_spring\_cloud](#output\_azure\_spring\_cloud) | Name for `azure_spring_cloud` resource. |
| <a name="output_azure_sql_server"></a> [azure\_sql\_server](#output\_azure\_sql\_server) | Name for `azure_sql_server` resource. |
| <a name="output_bastion"></a> [bastion](#output\_bastion) | Name for `bastion` resource. |
| <a name="output_batch_account"></a> [batch\_account](#output\_batch\_account) | Name for `batch_account` resource. |
| <a name="output_blockchain_service"></a> [blockchain\_service](#output\_blockchain\_service) | Name for `blockchain_service` resource. |
| <a name="output_blueprint"></a> [blueprint](#output\_blueprint) | Name for `blueprint` resource. |
| <a name="output_bot_channel_registration"></a> [bot\_channel\_registration](#output\_bot\_channel\_registration) | Name for `bot_channel_registration` resource. |
| <a name="output_cdn_profile"></a> [cdn\_profile](#output\_cdn\_profile) | Name for `cdn_profile` resource. |
| <a name="output_cloud_simple_node"></a> [cloud\_simple\_node](#output\_cloud\_simple\_node) | Name for `cloud_simple_node` resource. |
| <a name="output_cloud_simple_service"></a> [cloud\_simple\_service](#output\_cloud\_simple\_service) | Name for `cloud_simple_service` resource. |
| <a name="output_cloud_simple_vm"></a> [cloud\_simple\_vm](#output\_cloud\_simple\_vm) | Name for `cloud_simple_vm` resource. |
| <a name="output_connections"></a> [connections](#output\_connections) | Name for `connections` resource. |
| <a name="output_container_instance"></a> [container\_instance](#output\_container\_instance) | Name for `container_instance` resource. |
| <a name="output_container_registry"></a> [container\_registry](#output\_container\_registry) | Name for `container_registry` resource. |
| <a name="output_cosmos_db"></a> [cosmos\_db](#output\_cosmos\_db) | Name for `cosmos_db` resource. |
| <a name="output_data_box"></a> [data\_box](#output\_data\_box) | Name for `data_box` resource. |
| <a name="output_data_box_edge_gateway"></a> [data\_box\_edge\_gateway](#output\_data\_box\_edge\_gateway) | Name for `data_box_edge_gateway` resource. |
| <a name="output_data_collection_rule"></a> [data\_collection\_rule](#output\_data\_collection\_rule) | Name for `data_collection_rule` resource. |
| <a name="output_data_collection_endpoint"></a> [data\_collection\_endpoint](#output\_data\_collection\_endpoint) | Name for `data_collection_endpoint` resource. |
| <a name="output_data_factories"></a> [data\_factories](#output\_data\_factories) | Name for `data_factories` resource. |
| <a name="output_data_lake_analytics"></a> [data\_lake\_analytics](#output\_data\_lake\_analytics) | Name for `data_lake_analytics` resource. |
| <a name="output_data_lake_storage_gen1"></a> [data\_lake\_storage\_gen1](#output\_data\_lake\_storage\_gen1) | Name for `data_lake_storage_gen1` resource. |
| <a name="output_data_lake_storage_gen_2"></a> [data\_lake\_storage\_gen\_2](#output\_data\_lake\_storage\_gen\_2) | Name for `data_lake_storage_gen_2` resource. |
| <a name="output_data_share"></a> [data\_share](#output\_data\_share) | Name for `data_share` resource. |
| <a name="output_databricks"></a> [databricks](#output\_databricks) | Name for `databricks` resource. |
| <a name="output_ddos_protection"></a> [ddos\_protection](#output\_ddos\_protection) | Name for `ddos_protection` resource. |
| <a name="output_deny_network_security_group"></a> [deny\_network\_security\_group](#output\_deny\_network\_security\_group) | Name for `deny_network_security_group` resource. |
| <a name="output_device_provisioning_service"></a> [device\_provisioning\_service](#output\_device\_provisioning\_service) | Name for `device_provisioning_service` resource. |
| <a name="output_diagnostic_settings_suffix"></a> [diagnostic\_settings\_suffix](#output\_diagnostic\_settings\_suffix) | Name for `diagnostic_settings_suffix` resource. |
| <a name="output_elastic_job_agents"></a> [elastic\_job\_agents](#output\_elastic\_job\_agents) | Name for `elastic_job_agents` resource. |
| <a name="output_event_grid_domain"></a> [event\_grid\_domain](#output\_event\_grid\_domain) | Name for `event_grid_domain` resource. |
| <a name="output_event_grid_topic"></a> [event\_grid\_topic](#output\_event\_grid\_topic) | Name for `event_grid_topic` resource. |
| <a name="output_event_hub_cluster"></a> [event\_hub\_cluster](#output\_event\_hub\_cluster) | Name for `event_hub_cluster` resource. |
| <a name="output_event_hubs"></a> [event\_hubs](#output\_event\_hubs) | Name for `event_hubs` resource. |
| <a name="output_eventgrid_domain_topic"></a> [eventgrid\_domain\_topic](#output\_eventgrid\_domain\_topic) | Name for `eventgrid_domain_topic` resource. |
| <a name="output_eventgrid_event_subscription"></a> [eventgrid\_event\_subscription](#output\_eventgrid\_event\_subscription) | Name for `eventgrid_event_subscription` resource. |
| <a name="output_eventgrid_system_topic"></a> [eventgrid\_system\_topic](#output\_eventgrid\_system\_topic) | Name for `eventgrid_system_topic` resource. |
| <a name="output_eventhub_namespace"></a> [eventhub\_namespace](#output\_eventhub\_namespace) | Name for `eventhub_namespace` resource. |
| <a name="output_express_route_circuit"></a> [express\_route\_circuit](#output\_express\_route\_circuit) | Name for `express_route_circuit` resource. |
| <a name="output_front_door"></a> [front\_door](#output\_front\_door) | Name for `front_door` resource. |
| <a name="output_function_app"></a> [function\_app](#output\_function\_app) | Name for `function_app` resource. |
| <a name="output_host"></a> [host](#output\_host) | Name for `host` resource. |
| <a name="output_host_group"></a> [host\_group](#output\_host\_group) | Name for `host_group` resource. |
| <a name="output_image"></a> [image](#output\_image) | Name for `image` resource. |
| <a name="output_integration_account"></a> [integration\_account](#output\_integration\_account) | Name for `integration_account` resource. |
| <a name="output_integration_service_environment"></a> [integration\_service\_environment](#output\_integration\_service\_environment) | Name for `integration_service_environment` resource. |
| <a name="output_iot_central_application"></a> [iot\_central\_application](#output\_iot\_central\_application) | Name for `iot_central_application` resource. |
| <a name="output_iot_hub"></a> [iot\_hub](#output\_iot\_hub) | Name for `iot_hub` resource. |
| <a name="output_ip_configuration"></a> [ip\_configuration](#output\_ip\_configuration) | Name for `ip_configuration` resource. |
| <a name="output_key_vault"></a> [key\_vault](#output\_key\_vault) | Name for `key_vault` resource. |
| <a name="output_kubernetes_service"></a> [kubernetes\_service](#output\_kubernetes\_service) | Name for `kubernetes_service` resource. |
| <a name="output_load_balancer"></a> [load\_balancer](#output\_load\_balancer) | Name for `load_balancer` resource. |
| <a name="output_local_network_gateway"></a> [local\_network\_gateway](#output\_local\_network\_gateway) | Name for `local_network_gateway` resource. |
| <a name="output_lock"></a> [lock](#output\_lock) | Name for `lock` resource. |
| <a name="output_log_analytics_workspace"></a> [log\_analytics\_workspace](#output\_log\_analytics\_workspace) | Name for `log_analytics_workspace` resource. |
| <a name="output_logic_app"></a> [logic\_app](#output\_logic\_app) | Name for `logic_app` resource. |
| <a name="output_logic_apps_custom_connector"></a> [logic\_apps\_custom\_connector](#output\_logic\_apps\_custom\_connector) | Name for `logic_apps_custom_connector` resource. |
| <a name="output_machine_learning"></a> [machine\_learning](#output\_machine\_learning) | Name for `machine_learning` resource. |
| <a name="output_managed_identity"></a> [managed\_identity](#output\_managed\_identity) | Name for `managed_identity` resource. |
| <a name="output_management_group"></a> [management\_group](#output\_management\_group) | Name for `management_group` resource. |
| <a name="output_media_service"></a> [media\_service](#output\_media\_service) | Name for `media_service` resource. |
| <a name="output_mesh_application"></a> [mesh\_application](#output\_mesh\_application) | Name for `mesh_application` resource. |
| <a name="output_network_interface"></a> [network\_interface](#output\_network\_interface) | Name for `network_interface` resource. |
| <a name="output_network_profile"></a> [network\_profile](#output\_network\_profile) | Name for `network_profile` resource. |
| <a name="output_network_watcher"></a> [network\_watcher](#output\_network\_watcher) | Name for `network_watcher` resource. |
| <a name="output_notification_hub"></a> [notification\_hub](#output\_notification\_hub) | Name for `notification_hub` resource. |
| <a name="output_on_premise_data_gateway"></a> [on\_premise\_data\_gateway](#output\_on\_premise\_data\_gateway) | Name for `on_premise_data_gateway` resource. |
| <a name="output_policy_assignment"></a> [policy\_assignment](#output\_policy\_assignment) | Name for `policy_assignment` resource. |
| <a name="output_policy_definition"></a> [policy\_definition](#output\_policy\_definition) | Name for `policy_definition` resource. |
| <a name="output_power_bi_embedded"></a> [power\_bi\_embedded](#output\_power\_bi\_embedded) | Name for `power_bi_embedded` resource. |
| <a name="output_private_dns_zone"></a> [private\_dns\_zone](#output\_private\_dns\_zone) | Name for `private_dns_zone` resource. |
| <a name="output_private_endpoint"></a> [private\_endpoint](#output\_private\_endpoint) | Name for `private_endpoint` resource. |
| <a name="output_private_service_connection"></a> [private\_service\_connection](#output\_private\_service\_connection) | Name for `private_service_connection` resource. |
| <a name="output_proximity_placement_group"></a> [proximity\_placement\_group](#output\_proximity\_placement\_group) | Name for `proximity_placement_group` resource. |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | Name for `public_ip` resource. |
| <a name="output_public_ip_prefix"></a> [public\_ip\_prefix](#output\_public\_ip\_prefix) | Name for `public_ip_prefix` resource. |
| <a name="output_recovery_service_vault"></a> [recovery\_service\_vault](#output\_recovery\_service\_vault) | Name for `recovery_service_vault` resource. |
| <a name="output_relay"></a> [relay](#output\_relay) | Name for `relay` resource. |
| <a name="output_resource_group"></a> [resource\_group](#output\_resource\_group) | Name for `resource_group` resource. |
| <a name="output_resource_health_alert"></a> [resource\_health\_alert](#output\_resource\_health\_alert) | Name for `resource_health_alert` resource. |
| <a name="output_route_filter"></a> [route\_filter](#output\_route\_filter) | Name for `route_filter` resource. |
| <a name="output_route_static"></a> [route\_static](#output\_route\_static) | Name for `route_static` resource. |
| <a name="output_route_table"></a> [route\_table](#output\_route\_table) | Name for `route_table` resource. |
| <a name="output_search_service"></a> [search\_service](#output\_search\_service) | Name for `search_service` resource. |
| <a name="output_sendgrid_account"></a> [sendgrid\_account](#output\_sendgrid\_account) | Name for `sendgrid_account` resource. |
| <a name="output_service_bus"></a> [service\_bus](#output\_service\_bus) | Name for `service_bus` resource. |
| <a name="output_service_bus_namespace"></a> [service\_bus\_namespace](#output\_service\_bus\_namespace) | Name for `service_bus_namespace` resource. |
| <a name="output_service_bus_queue"></a> [service\_bus\_queue](#output\_service\_bus\_queue) | Name for `service_bus_queue` resource. |
| <a name="output_service_bus_subscription"></a> [service\_bus\_subscription](#output\_service\_bus\_subscription) | Name for `service_bus_subscription` resource. |
| <a name="output_service_bus_topic"></a> [service\_bus\_topic](#output\_service\_bus\_topic) | Name for `service_bus_topic` resource. |
| <a name="output_service_endpoint_policy"></a> [service\_endpoint\_policy](#output\_service\_endpoint\_policy) | Name for `service_endpoint_policy` resource. |
| <a name="output_service_fabric_cluster"></a> [service\_fabric\_cluster](#output\_service\_fabric\_cluster) | Name for `service_fabric_cluster` resource. |
| <a name="output_service_health_alert"></a> [service\_health\_alert](#output\_service\_health\_alert) | Name for `service_health_alert` resource. |
| <a name="output_service_principal"></a> [service\_principal](#output\_service\_principal) | Name for `service_principal` resource. |
| <a name="output_snapshot"></a> [snapshot](#output\_snapshot) | Name for `snapshot` resource. |
| <a name="output_sql_data_warehouse"></a> [sql\_data\_warehouse](#output\_sql\_data\_warehouse) | Name for `sql_data_warehouse` resource. |
| <a name="output_sql_database"></a> [sql\_database](#output\_sql\_database) | Name for `sql_database` resource. |
| <a name="output_sql_elastic_pool"></a> [sql\_elastic\_pool](#output\_sql\_elastic\_pool) | Name for `sql_elastic_pool` resource. |
| <a name="output_sql_hdinsights_cluster"></a> [sql\_hdinsights\_cluster](#output\_sql\_hdinsights\_cluster) | Name for `sql_hdinsights_cluster` resource. |
| <a name="output_sql_managed_instance"></a> [sql\_managed\_instance](#output\_sql\_managed\_instance) | Name for `sql_managed_instance` resource. |
| <a name="output_sql_server_registrie"></a> [sql\_server\_registrie](#output\_sql\_server\_registrie) | Name for `sql_server_registrie` resource. |
| <a name="output_sql_virtual_machine"></a> [sql\_virtual\_machine](#output\_sql\_virtual\_machine) | Name for `sql_virtual_machine` resource. |
| <a name="output_storage_account"></a> [storage\_account](#output\_storage\_account) | Name for `storage_account` resource. |
| <a name="output_storsimple_data_manager"></a> [storsimple\_data\_manager](#output\_storsimple\_data\_manager) | Name for `storsimple_data_manager` resource. |
| <a name="output_stream_analytics_job"></a> [stream\_analytics\_job](#output\_stream\_analytics\_job) | Name for `stream_analytics_job` resource. |
| <a name="output_subnet"></a> [subnet](#output\_subnet) | Name for `subnet` resource. |
| <a name="output_subscription"></a> [subscription](#output\_subscription) | Name for `subscription` resource. |
| <a name="output_time_series_insights_environment"></a> [time\_series\_insights\_environment](#output\_time\_series\_insights\_environment) | Name for `time_series_insights_environment` resource. |
| <a name="output_traffic_manager"></a> [traffic\_manager](#output\_traffic\_manager) | Name for `traffic_manager` resource. |
| <a name="output_virtual_machine"></a> [virtual\_machine](#output\_virtual\_machine) | Name for `virtual_machine` resource. |
| <a name="output_virtual_machine_data_disk"></a> [virtual\_machine\_data\_disk](#output\_virtual\_machine\_data\_disk) | Name for `virtual_machine_data_disk` resource. |
| <a name="output_virtual_machine_extension"></a> [virtual\_machine\_extension](#output\_virtual\_machine\_extension) | Name for `virtual_machine_extension` resource. |
| <a name="output_virtual_machine_network_interface"></a> [virtual\_machine\_network\_interface](#output\_virtual\_machine\_network\_interface) | Name for `virtual_machine_network_interface` resource. |
| <a name="output_virtual_machine_os_disk"></a> [virtual\_machine\_os\_disk](#output\_virtual\_machine\_os\_disk) | Name for `virtual_machine_os_disk` resource. |
| <a name="output_virtual_machine_scale_set"></a> [virtual\_machine\_scale\_set](#output\_virtual\_machine\_scale\_set) | Name for `virtual_machine_scale_set` resource. |
| <a name="output_virtual_network"></a> [virtual\_network](#output\_virtual\_network) | Name for `virtual_network` resource. |
| <a name="output_virtual_network_gateway"></a> [virtual\_network\_gateway](#output\_virtual\_network\_gateway) | Name for `virtual_network_gateway` resource. |
| <a name="output_virtual_network_peering"></a> [virtual\_network\_peering](#output\_virtual\_network\_peering) | Name for `virtual_network_peering` resource. |
| <a name="output_virtual_wan"></a> [virtual\_wan](#output\_virtual\_wan) | Name for `virtual_wan` resource. |
| <a name="output_waf_policy"></a> [waf\_policy](#output\_waf\_policy) | Name for `waf_policy` resource. |

## Resources

No resources.

## Modules

No modules.
<!-- END_TF_DOCS -->