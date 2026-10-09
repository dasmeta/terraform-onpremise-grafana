# selector

Shared PromQL matcher construction for Kafka Connect widgets and alerts.
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
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Optional cluster label value | `string` | `""` | no |
| <a name="input_cluster_label"></a> [cluster\_label](#input\_cluster\_label) | Optional cluster label name | `string` | `""` | no |
| <a name="input_extra_filters"></a> [extra\_filters](#input\_extra\_filters) | Optional extra PromQL matchers, for example job=~"example-connect-status-exporter" | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Optional PromQL namespace matcher | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_matchers"></a> [matchers](#output\_matchers) | PromQL matchers without surrounding braces |
| <a name="output_selector"></a> [selector](#output\_selector) | PromQL selector including braces, or empty when there are no matchers |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
