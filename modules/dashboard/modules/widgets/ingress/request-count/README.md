# request-count

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_base"></a> [base](#module\_base) | ../../base | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_by_host"></a> [by\_host](#input\_by\_host) | n/a | `bool` | `false` | no |
| <a name="input_by_path"></a> [by\_path](#input\_by\_path) | n/a | `bool` | `false` | no |
| <a name="input_by_status_path"></a> [by\_status\_path](#input\_by\_status\_path) | n/a | `bool` | `false` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_datasource_type"></a> [datasource\_type](#input\_datasource\_type) | n/a | `string` | `"prometheus"` | no |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | n/a | `string` | `"prometheus"` | no |
| <a name="input_filter"></a> [filter](#input\_filter) | Allows to define additional filter on metric | `string` | `""` | no |
| <a name="input_ingress_type"></a> [ingress\_type](#input\_ingress\_type) | n/a | `string` | `"nginx"` | no |
| <a name="input_only_5xx"></a> [only\_5xx](#input\_only\_5xx) | n/a | `bool` | `false` | no |
| <a name="input_period"></a> [period](#input\_period) | stats | `string` | `"$__rate_interval"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
