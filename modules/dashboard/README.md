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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 3.7.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_grafana"></a> [grafana](#provider\_grafana) | >= 3.7.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.6.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_block_ingress"></a> [block\_ingress](#module\_block\_ingress) | ./modules/blocks/ingress | n/a |
| <a name="module_block_redis"></a> [block\_redis](#module\_block\_redis) | ./modules/blocks/redis | n/a |
| <a name="module_block_service"></a> [block\_service](#module\_block\_service) | ./modules/blocks/service | n/a |
| <a name="module_block_sla"></a> [block\_sla](#module\_block\_sla) | ./modules/blocks/sla | n/a |
| <a name="module_container_cpu_widget"></a> [container\_cpu\_widget](#module\_container\_cpu\_widget) | ./modules/widgets/container/cpu | n/a |
| <a name="module_container_memory_widget"></a> [container\_memory\_widget](#module\_container\_memory\_widget) | ./modules/widgets/container/memory | n/a |
| <a name="module_container_network_traffic_widget"></a> [container\_network\_traffic\_widget](#module\_container\_network\_traffic\_widget) | ./modules/widgets/container/network-traffic | n/a |
| <a name="module_container_network_transmit_widget"></a> [container\_network\_transmit\_widget](#module\_container\_network\_transmit\_widget) | ./modules/widgets/container/network-transmit | n/a |
| <a name="module_container_network_widget"></a> [container\_network\_widget](#module\_container\_network\_widget) | ./modules/widgets/container/network | n/a |
| <a name="module_container_replicas_widget"></a> [container\_replicas\_widget](#module\_container\_replicas\_widget) | ./modules/widgets/container/replicas | n/a |
| <a name="module_container_request_count_widget"></a> [container\_request\_count\_widget](#module\_container\_request\_count\_widget) | ./modules/widgets/container/request-count | n/a |
| <a name="module_container_response_time_widget"></a> [container\_response\_time\_widget](#module\_container\_response\_time\_widget) | ./modules/widgets/container/response-time | n/a |
| <a name="module_container_restarts_widget"></a> [container\_restarts\_widget](#module\_container\_restarts\_widget) | ./modules/widgets/container/restarts | n/a |
| <a name="module_deployment_replicas_widget"></a> [deployment\_replicas\_widget](#module\_deployment\_replicas\_widget) | ./modules/widgets/deployment/replicas | n/a |
| <a name="module_ingress_connections_widget"></a> [ingress\_connections\_widget](#module\_ingress\_connections\_widget) | ./modules/widgets/ingress/connections | n/a |
| <a name="module_ingress_cpu_widget"></a> [ingress\_cpu\_widget](#module\_ingress\_cpu\_widget) | ./modules/widgets/ingress/cpu | n/a |
| <a name="module_ingress_latency_widget"></a> [ingress\_latency\_widget](#module\_ingress\_latency\_widget) | ./modules/widgets/ingress/latency | n/a |
| <a name="module_ingress_memory_widget"></a> [ingress\_memory\_widget](#module\_ingress\_memory\_widget) | ./modules/widgets/ingress/memory | n/a |
| <a name="module_ingress_request_count_widget"></a> [ingress\_request\_count\_widget](#module\_ingress\_request\_count\_widget) | ./modules/widgets/ingress/request-count | n/a |
| <a name="module_ingress_request_rate_widget"></a> [ingress\_request\_rate\_widget](#module\_ingress\_request\_rate\_widget) | ./modules/widgets/ingress/request-rate | n/a |
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
| <a name="module_widget_custom"></a> [widget\_custom](#module\_widget\_custom) | ./modules/widgets/custom | n/a |
| <a name="module_widget_sla_slo_sli_latency"></a> [widget\_sla\_slo\_sli\_latency](#module\_widget\_sla\_slo\_sli\_latency) | ./modules/widgets/sla-slo-sli/latency | n/a |
| <a name="module_widget_sla_slo_sli_main"></a> [widget\_sla\_slo\_sli\_main](#module\_widget\_sla\_slo\_sli\_main) | ./modules/widgets/sla-slo-sli/main | n/a |

## Resources

| Name | Type |
|------|------|
| [grafana_dashboard.metrics](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/dashboard) | resource |
| [random_string.grafana_dashboard_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data_source"></a> [data\_source](#input\_data\_source) | The grafana dashboard global/default datasource, will be used in widget items if they have no their custom ones | <pre>object({<br/>    uid  = string<br/>    type = optional(string, "prometheus")<br/>  })</pre> | n/a | yes |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Default values to be supplied to all modules. | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Dashboard name. Should not contain spaces and special chars. | `string` | n/a | yes |
| <a name="input_rows"></a> [rows](#input\_rows) | List of widgets to be inserted into the dashboard. See ./modules/widgets folder to see list of available widgets. | `any` | n/a | yes |
| <a name="input_variables"></a> [variables](#input\_variables) | Allows to define variables to be used in dashboard | <pre>list(object({<br/>    name        = string<br/>    type        = optional(string, "custom")<br/>    hide        = optional(number, 0)<br/>    includeAll  = optional(bool, false)<br/>    multi       = optional(bool, false)<br/>    query       = optional(string, "")<br/>    queryValue  = optional(string, "")<br/>    skipUrlSync = optional(bool, false)<br/>    options = optional(list(object({<br/>      selected = optional(bool, false)<br/>      value    = string<br/>      text     = optional(string, null)<br/>    })), [])<br/>    }<br/>  ))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dump"></a> [dump](#output\_dump) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
