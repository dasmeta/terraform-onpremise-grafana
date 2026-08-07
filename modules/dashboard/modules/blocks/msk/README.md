# msk

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
| <a name="input_block_name"></a> [block\_name](#input\_block\_name) | Widget block name | `string` | `"MSK"` | no |
| <a name="input_broker_ids"></a> [broker\_ids](#input\_broker\_ids) | Broker IDs to include in broker-level MSK metrics | `list(string)` | <pre>[<br/>  "1",<br/>  "2",<br/>  "3"<br/>]</pre> | no |
| <a name="input_cluster_names"></a> [cluster\_names](#input\_cluster\_names) | List of MSK cluster names (CloudWatch Cluster Name dimension) | `list(string)` | n/a | yes |
| <a name="input_consumer_groups"></a> [consumer\_groups](#input\_consumer\_groups) | Optional consumer groups for lag panels | `list(string)` | `[]` | no |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | Datasource uid for the metrics | `string` | `"cloudwatch"` | no |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"auto"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"eu-central-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | MSK dashboard block widget rows |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
