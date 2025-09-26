# prometheus


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >2.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.prometheus](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | prometheus chart version | `string` | `"75.8.0"` | no |
<<<<<<< HEAD
| <a name="input_configs"></a> [configs](#input\_configs) | Values to send to Prometheus template values file | <pre>object({<br/>    retention_days = optional(string, "15d")<br/>    storage_class  = optional(string, "")<br/>    storage_size   = optional(string, "100Gi")<br/>    access_modes   = optional(list(string), ["ReadWriteOnce"])<br/>    resources = optional(object({<br/>      request = optional(object({<br/>        cpu = optional(string, "1")<br/>        mem = optional(string, "2500Mi")<br/>      }), {})<br/>      limit = optional(object({<br/>        cpu = optional(string, "2")<br/>        mem = optional(string, "3Gi")<br/>      }), {})<br/>    }), {})<br/>    replicas                     = optional(number, 1)<br/>    enable_alertmanager          = optional(bool, true)<br/>    scrape_helm_chart_components = optional(bool, true)<br/>    additional_scrape_configs    = optional(any, []) # allows to specify additional scrape configs for prometheus. Example can be found in tests/prometheus-additional-scrape-configs/1-example.tf<br/>    ingress = optional(object({<br/>      enabled     = optional(bool, false)<br/>      type        = optional(string, "nginx")<br/>      public      = optional(bool, true)<br/>      tls_enabled = optional(bool, true)<br/><br/>      annotations = optional(map(string), {})<br/>      hosts       = optional(list(string), ["prometheus.example.com"])<br/>      path        = optional(list(string), ["/"])<br/>      path_type   = optional(string, "Prefix")<br/>    }), {})<br/>    kubelet_metrics = optional(list(string), ["container_cpu_.*", "container_memory_.*", "kube_pod_container_status_.*",<br/>      "kube_pod_container_resource_*", "container_network_.*", "kube_pod_resource_limit",<br/>      "kube_pod_resource_request", "pod_cpu_usage_seconds_total", "pod_memory_usage_bytes",<br/>      "kubelet_volume_stats.*", "volume_operation_total_seconds"]<br/>    )<br/>    additional_args = optional(list(object({<br/>      name  = string<br/>      value = string<br/>      })), [<br/>      {<br/>        name  = "query.max-concurrency"<br/>        value = "64"<br/>      },<br/>      {<br/>        name  = "query.timeout"<br/>        value = "2m"<br/>      },<br/>      {<br/>        name  = "query.max-samples"<br/>        value = "75000000"<br/>      }<br/>    ])<br/>  })</pre> | `{}` | no |
=======
| <a name="input_configs"></a> [configs](#input\_configs) | Values to send to Prometheus template values file | <pre>object({<br/>    retention_days = optional(string, "15d")<br/>    storage_class  = optional(string, "")<br/>    storage_size   = optional(string, "100Gi")<br/>    access_modes   = optional(list(string), ["ReadWriteOnce"])<br/>    resources = optional(object({<br/>      request = optional(object({<br/>        cpu = optional(string, "1")<br/>        mem = optional(string, "2Gi")<br/>      }), {})<br/>      limit = optional(object({<br/>        cpu = optional(string, "2")<br/>        mem = optional(string, "3Gi")<br/>      }), {})<br/>    }), {})<br/>    replicas                     = optional(number, 1)<br/>    enable_alertmanager          = optional(bool, true)<br/>    scrape_helm_chart_components = optional(bool, true)<br/>    additional_scrape_configs    = optional(any, []) # allows to specify additional scrape configs for prometheus. Example can be found in tests/prometheus-additional-scrape-configs/1-example.tf<br/>    ingress = optional(object({<br/>      enabled     = optional(bool, false)<br/>      type        = optional(string, "nginx")<br/>      public      = optional(bool, true)<br/>      tls_enabled = optional(bool, true)<br/><br/>      annotations = optional(map(string), {})<br/>      hosts       = optional(list(string), ["prometheus.example.com"])<br/>      path        = optional(list(string), ["/"])<br/>      path_type   = optional(string, "Prefix")<br/>    }), {})<br/>    kubelet_metrics = optional(list(string), ["container_cpu_.*", "container_memory_.*", "kube_pod_container_status_.*",<br/>      "kube_pod_container_resource_.*", "container_network_.*", "kube_pod_resource_limit",<br/>      "kube_pod_resource_request", "pod_cpu_usage_seconds_total", "pod_memory_usage_bytes",<br/>      "kubelet_volume_stats.*", "volume_operation_total_seconds.*", "container_fs_.*"]<br/>    )<br/>  })</pre> | `{}` | no |
>>>>>>> 966e18c (fix(DMVP-8288): add volume widgets to service, allow legend formatting)
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace to use for deployment | `string` | `"monitoring"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | prometheus release name | `string` | `"prometheus"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
