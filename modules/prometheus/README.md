# prometheus

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
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
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | prometheus chart version | `string` | `"75.8.0"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | Values to send to Prometheus template values file | <pre>object({<br/>    retention_days = optional(string, "15d")<br/>    storage_class  = optional(string, "")<br/>    storage_size   = optional(string, "100Gi")<br/>    access_modes   = optional(list(string), ["ReadWriteOnce"])<br/>    resources = optional(object({<br/>      request = optional(object({<br/>        cpu = optional(string, "500m")<br/>        mem = optional(string, "500Mi")<br/>      }), {})<br/>      limit = optional(object({<br/>        cpu = optional(string, "1")<br/>        mem = optional(string, "1Gi")<br/>      }), {})<br/>    }), {})<br/>    replicas            = optional(number, 2)<br/>    enable_alertmanager = optional(bool, true)<br/>    ingress = optional(object({<br/>      enabled     = optional(bool, false)<br/>      type        = optional(string, "nginx")<br/>      public      = optional(bool, true)<br/>      tls_enabled = optional(bool, true)<br/><br/>      annotations = optional(map(string), {})<br/>      hosts       = optional(list(string), ["prometheus.example.com"])<br/>      path        = optional(list(string), ["/"])<br/>      path_type   = optional(string, "Prefix")<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace to use for deployment | `string` | `"monitoring"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
