# grafana

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | > 5.0 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 3.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >2.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_grafana"></a> [grafana](#provider\_grafana) | >= 3.0.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_grafana_cloudwatch_role"></a> [grafana\_cloudwatch\_role](#module\_grafana\_cloudwatch\_role) | dasmeta/iam/aws//modules/role | 1.3.0 |

## Resources

| Name | Type |
|------|------|
| [grafana_data_source.this](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/data_source) | resource |
| [helm_release.grafana](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | grafana chart version | `string` | `"8.11.1"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | Values to construct the values file for Grafana Helm chart | <pre>object({<br/>    resources = optional(object({<br/>      request = optional(object({<br/>        cpu = optional(string, "1")<br/>        mem = optional(string, "2Gi")<br/>      }), {})<br/>      limit = optional(object({<br/>        cpu = optional(string, "2")<br/>        mem = optional(string, "3Gi")<br/>      }), {})<br/>    }), {})<br/>    persistence = optional(object({<br/>      enabled = optional(bool, true)<br/>      type    = optional(string, "pvc")<br/>      size    = optional(string, "10Gi")<br/>    }), {})<br/>    ingress = optional(object({<br/>      type            = optional(string, "alb")<br/>      public          = optional(bool, true)<br/>      tls_enabled     = optional(bool, true)<br/>      alb_certificate = optional(string, "")<br/><br/>      annotations = optional(map(string), {})<br/>      hosts       = optional(list(string), ["grafana.example.com"])<br/>      path        = optional(string, "/")<br/>      path_type   = optional(string, "Prefix")<br/>    }), {})<br/><br/>    replicas  = optional(number, 1)<br/>    image_tag = optional(string, "11.4.2")<br/>  })</pre> | `{}` | no |
| <a name="input_datasources"></a> [datasources](#input\_datasources) | A list of datasources configurations for grafana. | `list(map(any))` | `[]` | no |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | admin password | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace to use for deployment | `string` | `"monitoring"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
