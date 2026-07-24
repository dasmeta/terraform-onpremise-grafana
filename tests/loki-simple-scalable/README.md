# loki-simple-scalable

Validates mode-aware in-cluster Loki URLs, SimpleScalable replica defaults, and storage guardrails.

This test uses the `loki-stack` submodule directly so URL resolution can be verified with `terraform plan` without applying Helm releases to a cluster.

## Expected outputs

After `terraform init` and `terraform apply` (or inspect plan outputs):

| Output | Expected value |
|--------|----------------|
| `simple_scalable_query_url` | `http://loki-read.monitoring.svc.cluster.local:3100` |
| `simple_scalable_push_url` | `http://loki-write.monitoring.svc.cluster.local:3100/loki/api/v1/push` |
| `simple_scalable_deployment_mode` | `SimpleScalable` |
| `single_binary_query_url` | `http://loki-sb.monitoring.svc.cluster.local:3100` |
| `single_binary_push_url` | `http://loki-sb.monitoring.svc.cluster.local:3100/loki/api/v1/push` |
| `single_binary_deployment_mode` | `SingleBinary` |

## SimpleScalable defaults verified in Helm values

When `deploymentMode = "SimpleScalable"` and component replica counts are not set:

- `read.replicas` defaults to **2**
- `write.replicas` defaults to **2** (overridden to **3** in this example)
- `backend.replicas` defaults to **1**

## Guardrails

`terraform validate` fails when `deploymentMode = "SimpleScalable"` is combined with filesystem-only storage.

## Run locally

```sh
cd tests/loki-simple-scalable
terraform init
terraform validate
terraform plan
```

To apply against a cluster (optional):

```sh
export KUBE_CONFIG_PATH=/path/to/kubeconfig
terraform apply
terraform output
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.17 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_loki_simple_scalable"></a> [loki\_simple\_scalable](#module\_loki\_simple\_scalable) | ../../modules/loki-stack | n/a |
| <a name="module_loki_single_binary"></a> [loki\_single\_binary](#module\_loki\_single\_binary) | ../../modules/loki-stack | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"monitoring"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_simple_scalable_deployment_mode"></a> [simple\_scalable\_deployment\_mode](#output\_simple\_scalable\_deployment\_mode) | n/a |
| <a name="output_simple_scalable_push_url"></a> [simple\_scalable\_push\_url](#output\_simple\_scalable\_push\_url) | n/a |
| <a name="output_simple_scalable_query_url"></a> [simple\_scalable\_query\_url](#output\_simple\_scalable\_query\_url) | n/a |
| <a name="output_single_binary_deployment_mode"></a> [single\_binary\_deployment\_mode](#output\_single\_binary\_deployment\_mode) | n/a |
| <a name="output_single_binary_push_url"></a> [single\_binary\_push\_url](#output\_single\_binary\_push\_url) | n/a |
| <a name="output_single_binary_query_url"></a> [single\_binary\_query\_url](#output\_single\_binary\_query\_url) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
