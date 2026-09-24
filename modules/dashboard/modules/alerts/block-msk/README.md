# block-msk

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
| <a name="input_alerts"></a> [alerts](#input\_alerts) | n/a | <pre>object({<br/>    enabled = optional(bool, false)<br/>    offline_partitions = optional(object({<br/>      enabled        = optional(bool, true)<br/>      threshold      = optional(number, 0)<br/>      pending_period = optional(string, null)<br/>      labels         = optional(any, {})<br/>      annotations    = optional(any, {})<br/>      group          = optional(string, null)<br/>      no_data_state  = optional(string, null)<br/>      exec_err_state = optional(string, null)<br/>    }), {})<br/>    labels      = optional(any, {})<br/>    annotations = optional(any, {})<br/>  })</pre> | `{}` | no |
| <a name="input_cluster_names"></a> [cluster\_names](#input\_cluster\_names) | List of MSK cluster names to monitor | `list(string)` | n/a | yes |
| <a name="input_datasource"></a> [datasource](#input\_datasource) | CloudWatch datasource UID | `string` | `"cloudwatch"` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | n/a | <pre>object({<br/>    enabled        = optional(bool, true)<br/>    group          = optional(string, null)<br/>    pending_period = optional(string, "5m")<br/>    labels         = optional(any, {})<br/>    no_data_state  = optional(string, "NoData")<br/>    exec_err_state = optional(string, "Error")<br/>  })</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for CloudWatch MSK metrics | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alert_rules"></a> [alert\_rules](#output\_alert\_rules) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
