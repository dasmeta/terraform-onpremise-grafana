# elasticache_redis New Connections

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
| <a name="input_cache_cluster_ids"></a> [cache\_cluster\_ids](#input\_cache\_cluster\_ids) | List of CacheClusterId for ElastiCache Redis | `list(string)` | n/a | yes |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | Grid position for the panel | <pre>object({<br/>    x      = number<br/>    y      = number<br/>    width  = number<br/>    height = number<br/>  })</pre> | n/a | yes |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | n/a | `string` | `"cloudwatch"` | no |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
