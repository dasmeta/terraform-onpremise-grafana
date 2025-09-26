# Module to create Grafana dashboard from json/hcl
## Yaml example
```
source: dasmeta/grafana/onpremise//modules/dashboard
version: x.y.z
variables:
  name: test-dashboard
  data_source:
    uid: "0000"
  rows:
    - type : block/sla
    - type : "block/ingress"
    - type : "block/service"
      name : "service-name-1"
      host : "example.com"
    - type : "block/service",
      name : "service-name-2"
    -
      - type : "text/title",
        text : "End"
```

## HCL example
```
module "this" {
  source  = "dasmeta/grafana/onpremise//modules/dashboard"
  version = "x.y.z"

  name        = "test-dashboard-with-blocks"
  data_source = {
    uid: "0000"
  }

  rows = [
    { "type" : "block/sla" },
    { type : "block/ingress" },
    { type : "block/service", name : "service-name-1", namespace: "dev", host : "example.com" },
    { type : "block/service", name : "service-name-2", namespace: "dev" },
    { type : text/title, text: "End"}
  ]
}
```

## How add new widget
1. create module in modules/widgets (copy from one)
2. implement data loading as required
3. add new widget tf module in widget-{widget-group-name | single}.tf file
4. add new widget line in widget_result local

## How add new block
1. create module in modules/blocks (copy from one)
2. implement data loading as required
3. add new block tf module in widget-blocks.tf
4. add new block line in blocks_results local
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_deepmerge"></a> [deepmerge](#requirement\_deepmerge) | 1.0.2 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | ~> 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_grafana"></a> [grafana](#provider\_grafana) | ~> 4.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_ingress_connections_widget"></a> [alb\_ingress\_connections\_widget](#module\_alb\_ingress\_connections\_widget) | ./modules/widgets/alb_ingress/connections | n/a |
| <a name="module_alb_ingress_request_count_widget"></a> [alb\_ingress\_request\_count\_widget](#module\_alb\_ingress\_request\_count\_widget) | ./modules/widgets/alb_ingress/connections | n/a |
| <a name="module_alb_ingress_target_http_response_widget"></a> [alb\_ingress\_target\_http\_response\_widget](#module\_alb\_ingress\_target\_http\_response\_widget) | ./modules/widgets/alb_ingress/target_http_response | n/a |
| <a name="module_alb_ingress_target_response_time_widget"></a> [alb\_ingress\_target\_response\_time\_widget](#module\_alb\_ingress\_target\_response\_time\_widget) | ./modules/widgets/alb_ingress/target_response_time | n/a |
| <a name="module_block_alb_ingress"></a> [block\_alb\_ingress](#module\_block\_alb\_ingress) | ./modules/blocks/alb_ingress | n/a |
| <a name="module_block_cloudwatch"></a> [block\_cloudwatch](#module\_block\_cloudwatch) | ./modules/blocks/cloudwatch | n/a |
| <a name="module_block_ingress"></a> [block\_ingress](#module\_block\_ingress) | ./modules/blocks/ingress | n/a |
| <a name="module_block_ingress_nginx_alerts"></a> [block\_ingress\_nginx\_alerts](#module\_block\_ingress\_nginx\_alerts) | ./modules/alerts/block-ingress-nginx | n/a |
| <a name="module_block_redis"></a> [block\_redis](#module\_block\_redis) | ./modules/blocks/redis | n/a |
| <a name="module_block_service"></a> [block\_service](#module\_block\_service) | ./modules/blocks/service | n/a |
| <a name="module_block_service_alerts"></a> [block\_service\_alerts](#module\_block\_service\_alerts) | ./modules/alerts/block-service | n/a |
| <a name="module_block_sla"></a> [block\_sla](#module\_block\_sla) | ./modules/blocks/sla | n/a |
| <a name="module_block_sla_nginx_alerts"></a> [block\_sla\_nginx\_alerts](#module\_block\_sla\_nginx\_alerts) | ./modules/alerts/block-sla-nginx | n/a |
| <a name="module_container_cpu_widget"></a> [container\_cpu\_widget](#module\_container\_cpu\_widget) | ./modules/widgets/container/cpu | n/a |
| <a name="module_container_memory_widget"></a> [container\_memory\_widget](#module\_container\_memory\_widget) | ./modules/widgets/container/memory | n/a |
| <a name="module_container_network_error_widget"></a> [container\_network\_error\_widget](#module\_container\_network\_error\_widget) | ./modules/widgets/container/network-error | n/a |
| <a name="module_container_network_traffic_widget"></a> [container\_network\_traffic\_widget](#module\_container\_network\_traffic\_widget) | ./modules/widgets/container/network-traffic | n/a |
| <a name="module_container_network_widget"></a> [container\_network\_widget](#module\_container\_network\_widget) | ./modules/widgets/container/network | n/a |
| <a name="module_container_replicas_widget"></a> [container\_replicas\_widget](#module\_container\_replicas\_widget) | ./modules/widgets/container/replicas | n/a |
| <a name="module_container_request_count_widget"></a> [container\_request\_count\_widget](#module\_container\_request\_count\_widget) | ./modules/widgets/container/request-count | n/a |
| <a name="module_container_response_time_widget"></a> [container\_response\_time\_widget](#module\_container\_response\_time\_widget) | ./modules/widgets/container/response-time | n/a |
| <a name="module_container_restarts_widget"></a> [container\_restarts\_widget](#module\_container\_restarts\_widget) | ./modules/widgets/container/restarts | n/a |
| <a name="module_container_volume_IOPS_widget"></a> [container\_volume\_IOPS\_widget](#module\_container\_volume\_IOPS\_widget) | ./modules/widgets/container/volume-IOPS | n/a |
| <a name="module_container_volume_capacity_widget"></a> [container\_volume\_capacity\_widget](#module\_container\_volume\_capacity\_widget) | ./modules/widgets/container/volume-capacity | n/a |
| <a name="module_container_volume_throughput_widget"></a> [container\_volume\_throughput\_widget](#module\_container\_volume\_throughput\_widget) | ./modules/widgets/container/volume-throughput | n/a |
| <a name="module_deployment_errors_widget"></a> [deployment\_errors\_widget](#module\_deployment\_errors\_widget) | ./modules/widgets/deployment/errors | n/a |
| <a name="module_deployment_replicas_widget"></a> [deployment\_replicas\_widget](#module\_deployment\_replicas\_widget) | ./modules/widgets/deployment/replicas | n/a |
| <a name="module_deployment_warns_widget"></a> [deployment\_warns\_widget](#module\_deployment\_warns\_widget) | ./modules/widgets/deployment/warns | n/a |
| <a name="module_ingress_connections_widget"></a> [ingress\_connections\_widget](#module\_ingress\_connections\_widget) | ./modules/widgets/ingress/connections | n/a |
| <a name="module_ingress_cpu_widget"></a> [ingress\_cpu\_widget](#module\_ingress\_cpu\_widget) | ./modules/widgets/ingress/cpu | n/a |
| <a name="module_ingress_latency_widget"></a> [ingress\_latency\_widget](#module\_ingress\_latency\_widget) | ./modules/widgets/ingress/latency | n/a |
| <a name="module_ingress_memory_widget"></a> [ingress\_memory\_widget](#module\_ingress\_memory\_widget) | ./modules/widgets/ingress/memory | n/a |
| <a name="module_ingress_request_count_widget"></a> [ingress\_request\_count\_widget](#module\_ingress\_request\_count\_widget) | ./modules/widgets/ingress/request-count | n/a |
| <a name="module_ingress_request_rate_widget"></a> [ingress\_request\_rate\_widget](#module\_ingress\_request\_rate\_widget) | ./modules/widgets/ingress/request-rate | n/a |
| <a name="module_instance_cpu_widget"></a> [instance\_cpu\_widget](#module\_instance\_cpu\_widget) | ./modules/widgets/cloudwatch/instance_cpu | n/a |
| <a name="module_instance_disk_widget"></a> [instance\_disk\_widget](#module\_instance\_disk\_widget) | ./modules/widgets/cloudwatch/instance_disk | n/a |
| <a name="module_instance_network_widget"></a> [instance\_network\_widget](#module\_instance\_network\_widget) | ./modules/widgets/cloudwatch/instance_network | n/a |
| <a name="module_logs_count_widget"></a> [logs\_count\_widget](#module\_logs\_count\_widget) | ./modules/widgets/logs/count | n/a |
| <a name="module_logs_error_rate_widget"></a> [logs\_error\_rate\_widget](#module\_logs\_error\_rate\_widget) | ./modules/widgets/logs/error-rate | n/a |
| <a name="module_logs_warning_rate_widget"></a> [logs\_warning\_rate\_widget](#module\_logs\_warning\_rate\_widget) | ./modules/widgets/logs/warning-rate | n/a |
| <a name="module_pod_cpu_widget"></a> [pod\_cpu\_widget](#module\_pod\_cpu\_widget) | ./modules/widgets/pod/cpu | n/a |
| <a name="module_pod_memory_widget"></a> [pod\_memory\_widget](#module\_pod\_memory\_widget) | ./modules/widgets/pod/memory | n/a |
| <a name="module_pod_restarts_widget"></a> [pod\_restarts\_widget](#module\_pod\_restarts\_widget) | ./modules/widgets/pod/restarts | n/a |
| <a name="module_redis_clients_widget"></a> [redis\_clients\_widget](#module\_redis\_clients\_widget) | ./modules/widgets/redis/clients | n/a |
| <a name="module_redis_connections_widget"></a> [redis\_connections\_widget](#module\_redis\_connections\_widget) | ./modules/widgets/redis/connections | n/a |
| <a name="module_redis_cpu_widget"></a> [redis\_cpu\_widget](#module\_redis\_cpu\_widget) | ./modules/widgets/redis/cpu | n/a |
| <a name="module_redis_errors_widget"></a> [redis\_errors\_widget](#module\_redis\_errors\_widget) | ./modules/widgets/redis/errors | n/a |
| <a name="module_redis_expired_evicted_keys_widget"></a> [redis\_expired\_evicted\_keys\_widget](#module\_redis\_expired\_evicted\_keys\_widget) | ./modules/widgets/redis/expired-evicted-keys | n/a |
| <a name="module_redis_expiring_notexpiring_keys_widget"></a> [redis\_expiring\_notexpiring\_keys\_widget](#module\_redis\_expiring\_notexpiring\_keys\_widget) | ./modules/widgets/redis/expiring-notexpiring-keys | n/a |
| <a name="module_redis_hits_misses_widget"></a> [redis\_hits\_misses\_widget](#module\_redis\_hits\_misses\_widget) | ./modules/widgets/redis/hits-misses | n/a |
| <a name="module_redis_keys_widget"></a> [redis\_keys\_widget](#module\_redis\_keys\_widget) | ./modules/widgets/redis/keys | n/a |
| <a name="module_redis_latency_widget"></a> [redis\_latency\_widget](#module\_redis\_latency\_widget) | ./modules/widgets/redis/latency | n/a |
| <a name="module_redis_max_uptime_widget"></a> [redis\_max\_uptime\_widget](#module\_redis\_max\_uptime\_widget) | ./modules/widgets/redis/max-uptime | n/a |
| <a name="module_redis_memory_widget"></a> [redis\_memory\_widget](#module\_redis\_memory\_widget) | ./modules/widgets/redis/memory | n/a |
| <a name="module_redis_network_widget"></a> [redis\_network\_widget](#module\_redis\_network\_widget) | ./modules/widgets/redis/network | n/a |
| <a name="module_redis_replicas_widget"></a> [redis\_replicas\_widget](#module\_redis\_replicas\_widget) | ./modules/widgets/redis/replicas | n/a |
| <a name="module_redis_restarts_widget"></a> [redis\_restarts\_widget](#module\_redis\_restarts\_widget) | ./modules/widgets/redis/restarts | n/a |
| <a name="module_redis_total_commands_widget"></a> [redis\_total\_commands\_widget](#module\_redis\_total\_commands\_widget) | ./modules/widgets/redis/total-commands | n/a |
| <a name="module_redis_total_memory_widget"></a> [redis\_total\_memory\_widget](#module\_redis\_total\_memory\_widget) | ./modules/widgets/redis/total-memory | n/a |
| <a name="module_text_title"></a> [text\_title](#module\_text\_title) | ./modules/widgets/text/title | n/a |
| <a name="module_text_title_with_collapse"></a> [text\_title\_with\_collapse](#module\_text\_title\_with\_collapse) | ./modules/widgets/text/title-with-collapse | n/a |
| <a name="module_text_title_with_link"></a> [text\_title\_with\_link](#module\_text\_title\_with\_link) | ./modules/widgets/text/title-with-link | n/a |
| <a name="module_widget_alerts"></a> [widget\_alerts](#module\_widget\_alerts) | ../alerts/modules/rules | n/a |
| <a name="module_widget_custom"></a> [widget\_custom](#module\_widget\_custom) | ./modules/widgets/custom | n/a |
| <a name="module_widget_sla_slo_sli_alb_availability"></a> [widget\_sla\_slo\_sli\_alb\_availability](#module\_widget\_sla\_slo\_sli\_alb\_availability) | ./modules/widgets/sla-slo-sli/alb_availability | n/a |
| <a name="module_widget_sla_slo_sli_alb_latency"></a> [widget\_sla\_slo\_sli\_alb\_latency](#module\_widget\_sla\_slo\_sli\_alb\_latency) | ./modules/widgets/sla-slo-sli/alb_latency | n/a |
| <a name="module_widget_sla_slo_sli_nginx_latency"></a> [widget\_sla\_slo\_sli\_nginx\_latency](#module\_widget\_sla\_slo\_sli\_nginx\_latency) | ./modules/widgets/sla-slo-sli/nginx_latency | n/a |
| <a name="module_widget_sla_slo_sli_nginx_main"></a> [widget\_sla\_slo\_sli\_nginx\_main](#module\_widget\_sla\_slo\_sli\_nginx\_main) | ./modules/widgets/sla-slo-sli/nginx_main | n/a |

## Resources

| Name | Type |
|------|------|
| [grafana_dashboard.metrics](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/dashboard) | resource |
| [grafana_folder.this](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/folder) | resource |
| [random_string.grafana_dashboard_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [grafana_folder.this](https://registry.terraform.io/providers/grafana/grafana/latest/docs/data-sources/folder) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts"></a> [alerts](#input\_alerts) | Allows to configure globally dashboard block/(sla\|ingress\|service) blocks/widgets related alerts | `any` | `{}` | no |
| <a name="input_create_folder"></a> [create\_folder](#input\_create\_folder) | If true, create folder in this module. If false, use existing folder. | `bool` | `false` | no |
| <a name="input_data_source"></a> [data\_source](#input\_data\_source) | The grafana dashboard global/default datasource, will be used in widget items if they have no their custom ones | <pre>object({<br/>    uid  = string<br/>    type = optional(string, "prometheus")<br/>  })</pre> | n/a | yes |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Default values to be supplied to all modules. | `any` | `{}` | no |
| <a name="input_folder_name"></a> [folder\_name](#input\_folder\_name) | The folder name to place grafana dashboard | `string` | `"application-dashboard"` | no |
| <a name="input_folder_name_uids"></a> [folder\_name\_uids](#input\_folder\_name\_uids) | Map of folder names to folder UIDs. If provided, will be used instead of data sources | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Dashboard name. Should not contain spaces and special chars. | `string` | n/a | yes |
| <a name="input_rows"></a> [rows](#input\_rows) | List of widgets to be inserted into the dashboard. See ./modules/widgets folder to see list of available widgets. | `any` | n/a | yes |
| <a name="input_variables"></a> [variables](#input\_variables) | Allows to define variables to be used in dashboard | <pre>list(object({<br/>    name        = string<br/>    type        = optional(string, "custom")<br/>    hide        = optional(number, 0)<br/>    includeAll  = optional(bool, false)<br/>    multi       = optional(bool, false)<br/>    query       = optional(string, "")<br/>    queryValue  = optional(string, "")<br/>    skipUrlSync = optional(bool, false)<br/>    options = optional(list(object({<br/>      selected = optional(bool, false)<br/>      value    = string<br/>      text     = optional(string, null)<br/>    })), [])<br/>    }<br/>  ))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_blocks_results"></a> [blocks\_results](#output\_blocks\_results) | n/a |
| <a name="output_rows"></a> [rows](#output\_rows) | n/a |
| <a name="output_widget_alert_rules"></a> [widget\_alert\_rules](#output\_widget\_alert\_rules) | n/a |
| <a name="output_widget_result"></a> [widget\_result](#output\_widget\_result) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
