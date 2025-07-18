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
| <a name="provider_aws"></a> [aws](#provider\_aws) | > 5.0 |
| <a name="provider_grafana"></a> [grafana](#provider\_grafana) | >= 3.0.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >2.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_grafana_cloudwatch_role"></a> [grafana\_cloudwatch\_role](#module\_grafana\_cloudwatch\_role) | dasmeta/iam/aws//modules/role | 1.3.0 |

## Resources

| Name | Type |
|------|------|
| [grafana_data_source.this](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/data_source) | resource |
| [helm_release.grafana](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.mysql](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_persistent_volume_claim.grafana_efs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | grafana chart version | `string` | `"9.2.9"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | name of the eks cluster | `string` | n/a | yes |
| <a name="input_configs"></a> [configs](#input\_configs) | Values to construct the values file for Grafana Helm chart | <pre>object({<br/>    resources = optional(object({<br/>      request = optional(object({<br/>        cpu = optional(string, "1")<br/>        mem = optional(string, "2Gi")<br/>      }), {})<br/>      limit = optional(object({<br/>        cpu = optional(string, "2")<br/>        mem = optional(string, "3Gi")<br/>      }), {})<br/>    }), {})<br/>    database = optional(object({           # configure external(or in helm created) database base storing/persisting grafana data<br/>      enabled       = optional(bool, true) # whether database based persistence is enabled<br/>      create        = optional(bool, true) # whether to create mysql databases or use already existing database<br/>      name          = optional(string, "grafana")<br/>      type          = optional(string, "mysql") # when we set external database we can set any sql compatible one like postgresql or ms sql, but when we create database it supports only mysql and changing this field do not affect<br/>      host          = optional(string, null)    # it will set right host for grafana mysql in case create=true<br/>      user          = optional(string, "grafana")<br/>      password      = optional(string, null)    # if not set it will use var.grafana_admin_password<br/>      root_password = optional(string, null)    # if not set it will use var.grafana_admin_password<br/>      persistence = optional(object({           # allows to configure created(when database.create=true) mysql databases storage/persistence configs<br/>        enabled      = optional(bool, true)     # whether to have created in k8s mysql database with persistence<br/>        size         = optional(string, "20Gi") # the size of primary persistent volume of mysql when creating it<br/>        storageClass = optional(string, "")     # if set "" it takes the default storage class of k8s<br/>      }), {})<br/>      storage_size = optional(string, "20Gi")           # the size of primary persistent volume of mysql when creating it<br/>      extra_flags  = optional(string, "--skip-log-bin") # allows to set extra flags(whitespace separated) on grafana mysql primary instance, we have by default skip-log-bin flag set to disable bin-logs which overload mysql disc and/but we do not use multi replica mysql here<br/><br/>      # TODO: implement multi-replica/redundant grafana mysql database creation possibility<br/>    }), {})<br/>    persistence = optional(object({ # configure pvc base storing/persisting grafana data(it uses sqlite DB in this mode), NOTE: we use mysql database for data storage by default and no need to enable persistence if DB is set, so that we have persistence disable here by default<br/>      enabled       = optional(bool, false)<br/>      type          = optional(string, "pvc")<br/>      size          = optional(string, "20Gi")<br/>      storage_class = optional(string, "gp2")<br/>    }), {})<br/>    ingress = optional(object({<br/>      type            = optional(string, "alb")<br/>      public          = optional(bool, true)<br/>      tls_enabled     = optional(bool, true)<br/>      alb_certificate = optional(string, "")<br/><br/>      annotations = optional(map(string), {})<br/>      hosts       = optional(list(string), ["grafana.example.com"])<br/>      path        = optional(string, "/")<br/>      path_type   = optional(string, "Prefix")<br/>    }), {})<br/><br/>    redundancy = optional(object({<br/>      enabled                  = optional(bool, false)<br/>      max_replicas             = optional(number, 4)<br/>      min_replicas             = optional(number, 1)<br/>      redundancy_storage_class = optional(string, "efs-sc-root")<br/>    }), {})<br/><br/>    trace_log_mapping = optional(object({<br/>      enabled       = optional(bool, false)<br/>      trace_pattern = optional(string, "trace_id=(\\w+)")<br/>    }), {})<br/>    replicas  = optional(number, 1)<br/>    image_tag = optional(string, "11.4.2")<br/>  })</pre> | `{}` | no |
| <a name="input_datasources"></a> [datasources](#input\_datasources) | A list of datasources configurations for grafana. | `list(map(any))` | `[]` | no |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | admin password | `string` | `""` | no |
| <a name="input_mysql_chart_version"></a> [mysql\_chart\_version](#input\_mysql\_chart\_version) | mysql chart version | `string` | `"13.0.2"` | no |
| <a name="input_mysql_release_name"></a> [mysql\_release\_name](#input\_mysql\_release\_name) | name of grafana mysql helm release | `string` | `"grafana-mysql"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace to use for deployment | `string` | `"monitoring"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_datasources"></a> [datasources](#output\_datasources) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
