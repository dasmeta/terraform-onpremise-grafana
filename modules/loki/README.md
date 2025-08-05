# loki

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >2.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | > 3.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | > 3.7 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.loki](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.promtail](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | loki chart version | `string` | `"6.30.1"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | Values to pass to loki helm chart | <pre>object({<br/>    loki = optional(object({<br/>      url                = optional(string, "")<br/>      log_volume_enabled = optional(bool, true)<br/>      service_account = optional(object({<br/>        enable      = optional(bool, true)<br/>        name        = optional(string, "loki")<br/>        annotations = optional(map(string), {})<br/>      }), {})<br/>      persistence = optional(object({<br/>        enabled       = optional(bool, true)<br/>        size          = optional(string, "20Gi")<br/>        storage_class = optional(string, "")<br/>        access_mode   = optional(string, "ReadWriteOnce")<br/>      }), {})<br/>      schema_configs = optional(list(object({<br/>        from         = optional(string, "2025-01-01")<br/>        object_store = optional(string, "filesystem")<br/>        store        = optional(string, "tsdb")<br/>        schema       = optional(string, "v13")<br/>        index = optional(object({<br/>          prefix = optional(string, "index_")<br/>          period = optional(string, "24h")<br/>        }))<br/>      })), [])<br/>      limits_config = optional(map(string), {})<br/>      storage = optional(any, {<br/>        type = "filesystem",<br/>        filesystem = {<br/>          chunks_directory    = "/var/loki/chunks"<br/>          rules_directory     = "/var/loki/rules"<br/>          admin_api_directory = "/var/loki/admin"<br/>        }<br/>        bucketNames = {<br/>          chunks = "unused-for-filesystem"<br/>          ruler  = "unused-for-filesystem"<br/>          admin  = "unused-for-filesystem"<br/>        }<br/>      })<br/>      replicas         = optional(number, 1)<br/>      retention_period = optional(string, "168h")<br/>      resources = optional(object({<br/>        request = optional(object({<br/>          cpu = optional(string, "1")<br/>          mem = optional(string, "1500Mi")<br/>        }), {})<br/>        limit = optional(object({<br/>          cpu = optional(string, "1500m")<br/>          mem = optional(string, "2000Mi")<br/>        }), {})<br/>      }), {})<br/>      ingress = optional(object({<br/>        enabled = optional(bool, false)<br/>        type    = optional(string, "nginx")<br/>        public  = optional(bool, true)<br/>        tls = optional(object({<br/>          enabled       = optional(bool, true)<br/>          cert_provider = optional(string, "letsencrypt-prod")<br/>        }), {})<br/><br/>        annotations = optional(map(string), {})<br/>        hosts       = optional(list(string), ["loki.example.com"])<br/>        path        = optional(string, "/")<br/>        path_type   = optional(string, "Prefix")<br/>      }), {})<br/>    }), {})<br/>    promtail = optional(object({<br/>      enabled               = optional(bool, true)<br/>      log_level             = optional(string, "info")<br/>      server_port           = optional(string, "3101")<br/>      clients               = optional(list(string), [])<br/>      log_format            = optional(string, "logfmt")<br/>      extra_scrape_configs  = optional(list(any), [])<br/>      extra_label_configs   = optional(list(map(string)), [])<br/>      extra_pipeline_stages = optional(any, [])<br/>      ignored_containers    = optional(list(string), [])<br/>      ignored_namespaces    = optional(list(string), [])<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace for deployment of chart | `string` | `"monitoring"` | no |
| <a name="input_promtail_chart_version"></a> [promtail\_chart\_version](#input\_promtail\_chart\_version) | promtail chart version | `string` | `"6.17.0"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | n/a | `string` | `"loki"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
