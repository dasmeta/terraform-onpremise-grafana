# main

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
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | `null` | no |
| <a name="input_balancer_name"></a> [balancer\_name](#input\_balancer\_name) | n/a | `string` | `null` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_data_source"></a> [data\_source](#input\_data\_source) | The custom datasource for widget item | <pre>object({<br/>    uid  = optional(string, null)<br/>    type = optional(string, "prometheus")<br/>  })</pre> | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | stats | `number` | `3` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
