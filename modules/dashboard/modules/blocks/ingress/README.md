# ingress

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
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | datasource uid for the metrics | `string` | `"prometheus"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace where nginx ingress controller is deployed | `string` | `"ingress-nginx"` | no |
| <a name="input_pod"></a> [pod](#input\_pod) | The name identifier/prefix of nginx ingress controller pods | `string` | `"ingress-nginx-controller"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | description |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
