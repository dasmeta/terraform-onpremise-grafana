# tempo

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
| [helm_release.tempo](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Tempo chart version | `string` | `"1.23.3"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | n/a | <pre>object({<br/>    storage = optional(object({<br/>      backend = optional(string, "local")<br/>      backend_configuration = optional(map(any), {<br/>        local = { path = "/var/tempo/traces" },<br/>        wal   = { path = "/var/tempo/wal" }<br/>      })<br/>    }), {})<br/>    enable_metrics_generator = optional(bool, true)<br/>    enable_service_monitor   = optional(bool, false)<br/>    tempo_role_name          = optional(string, "tempo-role")<br/><br/>    persistence = optional(object({<br/>      enabled       = optional(bool, true)<br/>      size          = optional(string, "20Gi")<br/>      storage_class = optional(string, "")<br/>    }), {})<br/><br/>    metrics_generator = optional(object({<br/>      enabled    = optional(bool, true)<br/>      remote_url = optional(string, "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/write")<br/>    }), {})<br/><br/>    service_account = optional(object({<br/>      name        = optional(string, "tempo")<br/>      annotations = optional(map(string), {})<br/>    }), {})<br/>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace for tempo deployment | `string` | `"monitoring"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tempo_url"></a> [tempo\_url](#output\_tempo\_url) | Internal Tempo service URL |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
