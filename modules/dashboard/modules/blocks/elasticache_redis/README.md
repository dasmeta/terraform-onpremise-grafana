# elasticache_redis

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
| <a name="input_block_name"></a> [block\_name](#input\_block\_name) | Widget block name | `string` | `"Redis (Queue)"` | no |
| <a name="input_cache_cluster_ids"></a> [cache\_cluster\_ids](#input\_cache\_cluster\_ids) | List of CacheClusterId for ElastiCache Redis | `list(string)` | n/a | yes |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | datasource uid for the metrics | `string` | `"cloudwatch"` | no |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"auto"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"eu-central-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | description |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
