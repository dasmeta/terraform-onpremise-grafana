# loki

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | > 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >2.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | > 3.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | > 5.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | > 3.7 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_loki_bucket"></a> [loki\_bucket](#module\_loki\_bucket) | dasmeta/s3/aws | 1.3.2 |
| <a name="module_loki_iam_eks_role"></a> [loki\_iam\_eks\_role](#module\_loki\_iam\_eks\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.53.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.loki_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [helm_release.loki](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.promtail](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | loki chart version | `string` | `"6.30.1"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | name of the eks cluster | `string` | `""` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | Values to pass to loki helm chart | <pre>object({<br/>    enable_test_pod = optional(bool, false)<br/>    loki = optional(object({<br/>      url                = optional(string, "")<br/>      log_volume_enabled = optional(bool, true)<br/>      send_logs_s3 = optional(object({<br/>        enable         = optional(bool, true)<br/>        bucket_name    = optional(string, "")<br/>        aws_role_arn   = optional(string, "")<br/>        retention_days = optional(number, 7) # remove log item after set days<br/>      }), {})<br/>      service_account = optional(object({<br/>        enable      = optional(bool, true)<br/>        name        = optional(string, "loki")<br/>        annotations = optional(map(string), {})<br/>      }), {})<br/>      persistence = optional(object({<br/>        enabled       = optional(bool, true)<br/>        size          = optional(string, "20Gi")<br/>        storage_class = optional(string, "gp2")<br/>        access_mode   = optional(string, "ReadWriteOnce")<br/>      }), {})<br/>      schema_configs = optional(list(object({<br/>        from         = optional(string, "2025-01-01")<br/>        object_store = optional(string, "s3")<br/>        store        = optional(string, "tsdb")<br/>        schema       = optional(string, "v13")<br/>        index = optional(object({<br/>          prefix = optional(string, "index_")<br/>          period = optional(string, "24h")<br/>        }))<br/>      })), [])<br/>      storage          = optional(map(any), { type = "filesystem" })<br/>      replicas         = optional(number, 1)<br/>      retention_period = optional(string, "168h")<br/>      resources = optional(object({<br/>        request = optional(object({<br/>          cpu = optional(string, "200m")<br/>          mem = optional(string, "250Mi")<br/>        }), {})<br/>        limit = optional(object({<br/>          cpu = optional(string, "400m")<br/>          mem = optional(string, "500Mi")<br/>        }), {})<br/>      }), {})<br/>    }), {})<br/>    promtail = optional(object({<br/>      enabled              = optional(bool, true)<br/>      log_level            = optional(string, "info")<br/>      server_port          = optional(string, "3101")<br/>      clients              = optional(list(string), [])<br/>      log_format           = optional(string, "logfmt")<br/>      extra_scrape_configs = optional(list(any), [])<br/>      extra_label_configs  = optional(list(map(string)), [])<br/>      ignored_containers   = optional(list(string), [])<br/>      ignored_namespaces   = optional(list(string), [])<br/>    }), {})<br/>    fluentbit_enabled = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace for deployment of chart | `string` | `"monitoring"` | no |
| <a name="input_promtail_chart_version"></a> [promtail\_chart\_version](#input\_promtail\_chart\_version) | promtail chart version | `string` | `"6.17.0"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | n/a | `string` | `"loki"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
