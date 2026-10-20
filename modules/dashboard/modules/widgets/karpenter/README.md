# karpenter

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_base"></a> [base](#module\_base) | ../base | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | Panel coordinates | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | Prometheus datasource UID | `string` | `"prometheus"` | no |
| <a name="input_extra_filters"></a> [extra\_filters](#input\_extra\_filters) | Additional PromQL label matchers appended to every query, for example `job="karpenter"` | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace where karpenter controller runs, karpenter metrics get this namespace label from the scrape target | `string` | `"karpenter"` | no |
| <a name="input_panel"></a> [panel](#input\_panel) | The karpenter panel to render, one of the keys in local.panels (for example `drift-duration`) | `string` | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | Prometheus range interval used by rate/increase queries | `string` | `"$__rate_interval"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | Grafana panel payload |
| <a name="output_expressions"></a> [expressions](#output\_expressions) | The PromQL expressions of the rendered panel, used in tests |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
