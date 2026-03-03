# ses

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
| <a name="input_block_name"></a> [block\_name](#input\_block\_name) | Widget block title | `string` | `"AWS SES"` | no |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | Datasource UID for CloudWatch metrics | `string` | `"cloudwatch"` | no |
| <a name="input_max"></a> [max](#input\_max) | Sending Quota gauge: max (null = auto) | `number` | `null` | no |
| <a name="input_min"></a> [min](#input\_min) | Sending Quota gauge: min (null = auto) | `number` | `null` | no |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"auto"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for SES metrics | `string` | `"eu-central-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | SES block rows (widget configs); types use aws-ses/* prefix with hyphens |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
