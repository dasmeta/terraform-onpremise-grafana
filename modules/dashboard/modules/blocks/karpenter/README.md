# karpenter

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
| <a name="input_block_name"></a> [block\_name](#input\_block\_name) | Dashboard block title | `string` | `"Karpenter"` | no |
| <a name="input_columns"></a> [columns](#input\_columns) | The number of widgets to place in each line | `number` | `3` | no |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | Prometheus datasource UID | `string` | `"prometheus"` | no |
| <a name="input_extra_filters"></a> [extra\_filters](#input\_extra\_filters) | Additional PromQL label matchers appended to every karpenter query, for example `job="karpenter"` or `cluster="prod"` | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace where karpenter controller runs, karpenter metrics get this namespace label from the scrape target so it is used to select karpenter metrics | `string` | `"karpenter"` | no |
| <a name="input_period"></a> [period](#input\_period) | Prometheus range interval used by rate/increase panels | `string` | `"$__rate_interval"` | no |
| <a name="input_widgets"></a> [widgets](#input\_widgets) | Allows to enable/disable karpenter block widget groups | <pre>object({<br/>    nodes          = optional(bool, true)  # nodes per nodepool/capacity type, nodes created/terminated, nodes not initialized<br/>    drift          = optional(bool, true)  # drifted nodes count and how long each node is in drifted state<br/>    disruption     = optional(bool, true)  # nodes disrupted by reason and disruption decisions<br/>    capacity       = optional(bool, true)  # pods waiting for capacity, longest pod wait per phase(decision, node launch) and nodepool usage against its limits<br/>    cloud_provider = optional(bool, true)  # cloud provider call errors (Create means node launch), available with every karpenter cloud provider<br/>    controller     = optional(bool, true)  # karpenter controller reconcile errors<br/>    interruption   = optional(bool, false) # interruption messages received/handled, only karpenter providers with an interruption queue (AWS SQS) expose these metrics, so it is opt-in<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | Karpenter dashboard block widget rows |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
