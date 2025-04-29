# tempo

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | > 5.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tempo_bucket"></a> [tempo\_bucket](#module\_tempo\_bucket) | dasmeta/s3/aws | 1.3.1 |
| <a name="module_tempo_iam_eks_role"></a> [tempo\_iam\_eks\_role](#module\_tempo\_iam\_eks\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.53.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.tempo_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [helm_release.tempo](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | grafana chart version | `string` | `"1.20.0"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | name of the eks cluster | `string` | n/a | yes |
| <a name="input_configs"></a> [configs](#input\_configs) | n/a | <pre>object({<br/>    tempo_role_arn           = optional(string, "")<br/>    storage_backend          = optional(string, "s3") # "local" or "s3"<br/>    bucket_name              = optional(string, "")<br/>    enable_metrics_generator = optional(bool, true)<br/>    enable_service_monitor   = optional(bool, true)<br/>    tempo_role_name          = optional(string, "tempo-s3-role")<br/><br/>    persistence = optional(object({<br/>      enabled       = optional(bool, true)<br/>      size          = optional(string, "20Gi")<br/>      storage_class = optional(string, "gp2")<br/>    }), {})<br/><br/>    metrics_generator = optional(object({<br/>      enabled    = optional(bool, true)<br/>      remote_url = optional(string, "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/write")<br/>    }), {})<br/><br/>    service_account = optional(object({<br/>      name        = optional(string, "tempo-serviceaccount")<br/>      annotations = optional(map(string), {})<br/>    }), {})<br/>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace for tempo deployment | `string` | `"monitoring"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tempo_url"></a> [tempo\_url](#output\_tempo\_url) | Internal Tempo service URL |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
