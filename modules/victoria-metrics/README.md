# victoria-metrics

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.17 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.17 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.victoria_metrics](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | victoria metrics cluster chart version | `string` | `"0.31.4"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | Values to send to VictoriaMetrics helm chart | <pre>object({<br/>    retention_period = optional(string, "30d")<br/>    vmstorage = optional(object({<br/>      replica_count = optional(number, 3)<br/>      storage_class = optional(string, "")<br/>      storage_size  = optional(string, "100Gi")<br/>      access_modes  = optional(list(string), ["ReadWriteOnce"])<br/>    }), {})<br/>    vminsert = optional(object({<br/>      replica_count = optional(number, 2)<br/>    }), {})<br/>    vmselect = optional(object({<br/>      replica_count = optional(number, 2)<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether create namespace if not exist | `bool` | `true` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Allows to pass extra/custom configs to victoria-metrics-cluster helm chart | `any` | `{}` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace to use for deployment | `string` | `"monitoring"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | victoria metrics release name | `string` | `"victoria-metrics"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | victoria metrics helm release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
