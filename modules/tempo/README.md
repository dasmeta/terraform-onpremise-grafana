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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | grafana chart version | `string` | `"1.18.3"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | n/a | <pre>object({<br/>    tempo_image_tag          = optional(string, "2.4.0")<br/>    tempo_role_arn           = optional(string, "")<br/>    storage_backend          = optional(string, "s3") # "local" or "s3"<br/>    bucket_name              = optional(string, "")<br/>    enable_metrics_generator = optional(bool, true)<br/>    enable_service_monitor   = optional(bool, true)<br/>    tempo_role_name          = optional(string, "tempo-s3-role")<br/>    oidc_provider_arn        = optional(string, "")<br/><br/>    persistence = optional(object({<br/>      enabled       = optional(bool, true)<br/>      size          = optional(string, "10Gi")<br/>      storage_class = optional(string, "gp2")<br/>    }), {})<br/><br/>    service_account = optional(object({<br/>      name        = optional(string, "tempo-serviceaccount")<br/>      annotations = optional(map(string), {})<br/>    }), {})<br/>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace for tempo deployment | `string` | `"monitoring"` | no |
| <a name="input_region"></a> [region](#input\_region) | aws region | `string` | `"eu-central-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tempo_url"></a> [tempo\_url](#output\_tempo\_url) | Internal Tempo service URL |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
