# loki

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | > 5.0 |
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
| [helm_release.loki](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | loki chart version | `string` | `"2.10.2"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | Values to pass to loki helm chart | <pre>object({<br/>    enable_test_pod = optional(bool, false)<br/>    loki = optional(object({<br/>      url            = optional(string, "")<br/>      volume_enabled = optional(bool, true)<br/>    }), {})<br/>    promtail = optional(object({<br/>      enabled              = optional(bool, true)<br/>      log_level            = optional(string, "info")<br/>      server_port          = optional(string, "3101")<br/>      clients              = optional(list(string), [])<br/>      log_format           = optional(string, "logfmt")<br/>      extra_scrape_configs = optional(list(any), [])<br/>      extra_label_configs  = optional(list(map(string)), [])<br/>      ignored_containers   = optional(list(string), [])<br/>      ignored_namespaces   = optional(list(string), [])<br/>    }), {})<br/>    fluentbit_enabled = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace for deployment of chart | `string` | `"monitoring"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | n/a | `string` | `"loki"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
