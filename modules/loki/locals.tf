locals {
  # Promtail related configs
  extra_relabel_configs = concat(
    try(var.configs.promtail.extra_relabel_configs, []),
    length(var.configs.promtail.ignored_namespaces) > 0 ?
    [{
      action        = "drop"
      source_labels = ["__meta_kubernetes_namespace"]
      regex         = format("(%s)", join("|", var.configs.promtail.ignored_namespaces))
    }] :
    [],
    length(var.configs.promtail.ignored_containers) > 0 ?
    [{
      action        = "drop"
      source_labels = ["__meta_kubernetes_pod_container_name"]
      regex         = format("(%s)", join("|", var.configs.promtail.ignored_containers))
    }] :
    []
  )
  extra_relabel_configs_yaml = yamlencode(local.extra_relabel_configs)
  extra_scrape_configs_yaml  = length(var.configs.promtail.extra_scrape_configs) > 0 ? yamlencode(var.configs.promtail.extra_scrape_configs) : ""

  # Loki related configs
  redundency_enabled = var.configs.loki.replicas > 1 ? true : false

  create_service_account      = try(var.configs.loki.service_account.enable, false) ? true : (var.configs.loki.send_logs_s3.enable ? true : false)
  loki_role                   = local.create_loki_role ? module.loki_iam_eks_role[0].iam_role_arn : (var.configs.loki.send_logs_s3.enable ? var.configs.loki.send_logs_s3.aws_role_arn : "")
  service_account_annotations = merge(var.configs.loki.service_account.annotations, var.configs.loki.send_logs_s3.enable ? { "eks.amazonaws.com/role-arn" = local.loki_role } : {})
  create_loki_role            = var.configs.loki.send_logs_s3.enable && var.configs.loki.send_logs_s3.aws_role_arn == ""
  eks_oidc_provider_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"

  s3_bucket_name = length(var.configs.loki.send_logs_s3.bucket_name) > 0 ? var.configs.loki.send_logs_s3.bucket_name : "loki-logs-${var.cluster_name}-${random_string.random.result}"
  default_loki_storage_config = {
    boltdb_shipper = {
      shared_store = "s3"
    }
    aws = {
      bucketnames      = local.s3_bucket_name
      region           = data.aws_region.current.name
      s3forcepathstyle = true
    }
  }
  loki_storage_configs = (
    var.configs.loki.send_logs_s3.enable && length(var.configs.loki.storage_configs) == 0
  ) ? merge({}, local.default_loki_storage_config) : merge({}, var.configs.loki.storage_configs)

  schema_configs = length(var.configs.loki.schema_configs) == 0 ? (
    var.configs.loki.send_logs_s3.enable ?
    [{
      from         = "2024-01-01"
      store        = "boltdb-shipper"
      object_store = "s3"
      schema       = "v11"
      index = {
        prefix = "index_"
        period = "24h"
      }
    }] : []
  ) : var.configs.loki.schema_configs
  schema_configs_yaml = yamlencode(local.schema_configs)
}
