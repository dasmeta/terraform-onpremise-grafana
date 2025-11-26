# sla

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
| <a name="input_balancer_name"></a> [balancer\_name](#input\_balancer\_name) | ALB name | `string` | n/a | yes |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | datasource uid for the metrics | `string` | `"prometheus"` | no |
| <a name="input_filter"></a> [filter](#input\_filter) | Allows to define additional filter on metrics | `string` | `""` | no |
| <a name="input_height"></a> [height](#input\_height) | The height of widgets | `number` | `6` | no |
| <a name="input_load_balancer_arn"></a> [load\_balancer\_arn](#input\_load\_balancer\_arn) | AWS Application LB arn | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |
| <a name="input_sla_ingress_type"></a> [sla\_ingress\_type](#input\_sla\_ingress\_type) | Type of the ingress resource | `string` | `"alb"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | description |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
