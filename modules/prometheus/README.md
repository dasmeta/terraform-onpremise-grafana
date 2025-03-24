# prometheus

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | > 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >2.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.prometheus](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configs"></a> [configs](#input\_configs) | Values to send to Prometheus template values file | <pre>object({<br/>    retention_days = optional(string, "15d")<br/>    storage_class  = optional(string, "efs-sc-root")<br/>    storage_size   = optional(string, "10Gi")<br/>    resources = optional(object({<br/>      request = optional(object({<br/>        cpu = optional(string, "500m")<br/>        mem = optional(string, "500Mi")<br/>      }), {})<br/>      limit = optional(object({<br/>        cpu = optional(string, "1")<br/>        mem = optional(string, "1Gi")<br/>      }), {})<br/>    }), {})<br/>    enable_alertmanager = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace to use for deployment | `string` | `"monitoring"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
