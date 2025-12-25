# rds

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
| <a name="input_block_name"></a> [block\_name](#input\_block\_name) | Widget block name | `string` | `"RDS"` | no |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | datasource uid for the metrics | `string` | `"cloudwatch"` | no |
| <a name="input_db_identifiers"></a> [db\_identifiers](#input\_db\_identifiers) | List of DBInstanceIdentifier for RDS instances | `list(string)` | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"auto"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"eu-central-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | description |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
