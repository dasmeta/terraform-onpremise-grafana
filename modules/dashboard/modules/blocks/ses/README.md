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
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"auto"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for SES metrics | `string` | `"eu-central-1"` | no |
| <a name="input_sending_quota_standard_options"></a> [sending\_quota\_standard\_options](#input\_sending\_quota\_standard\_options) | Standard options (min/max) for Sending Quota gauge | <pre>object({<br/>    min = optional(number)<br/>    max = optional(number)<br/>  })</pre> | <pre>{<br/>  "max": 100000<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | SES block rows (widget configs) |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
