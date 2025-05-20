# service

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_datasource_type"></a> [datasource\_type](#input\_datasource\_type) | datasource type | `string` | `"prometheus"` | no |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | datasource uid for the metrics | `string` | `"prometheus"` | no |
| <a name="input_host"></a> [host](#input\_host) | The service host name | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Service nameD | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | EKS namespace name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | description |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
