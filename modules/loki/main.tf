resource "helm_release" "loki" {
  chart            = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version
  timeout          = 600

  values = [
    templatefile("${path.module}/values/loki-values.yaml.tpl", {
      log_volume_enabled          = var.configs.loki.log_volume_enabled
      persistence_enabled         = var.configs.loki.persistence.enabled
      persistence_access_mode     = var.configs.loki.persistence.access_mode
      persistence_size            = var.configs.loki.persistence.size
      persistence_storage_class   = var.configs.loki.persistence.storage_class
      num_replicas                = var.configs.loki.replicas
      storage                     = jsonencode(var.configs.loki.storage)
      schema_configs              = jsonencode(var.configs.loki.schema_configs)
      create_service_account      = var.configs.loki.service_account.enable
      service_account_name        = try(var.configs.loki.service_account.name, "loki-service-account")
      service_account_annotations = var.configs.loki.service_account.annotations
      request_cpu                 = var.configs.loki.resources.request.cpu
      request_mem                 = var.configs.loki.resources.request.mem
      limit_cpu                   = var.configs.loki.resources.limit.cpu
      limit_mem                   = var.configs.loki.resources.limit.mem
      retention_period            = var.configs.loki.retention_period
      limits_config               = local.limits_config

      ingress_annotations = local.ingress_annotations
      ingress_hosts       = var.configs.loki.ingress.hosts
      ingress_path        = var.configs.loki.ingress.path
      ingress_path_type   = var.configs.loki.ingress.path_type
      ingress_tls_secrets = local.ingress_tls
      ingress_enabled     = var.configs.loki.ingress.enabled
      ingress_type        = var.configs.loki.ingress.type
      }
    )
  ]
}

resource "helm_release" "promtail" {
  count = var.configs.promtail.enabled ? 1 : 0

  chart            = "promtail"
  repository       = "https://grafana.github.io/helm-charts"
  name             = "${var.release_name}-promtail"
  namespace        = var.namespace
  create_namespace = false
  version          = var.promtail_chart_version
  timeout          = 300

  values = [
    templatefile("${path.module}/values/promtail-values.tpl", {
      promtail_log_level                = var.configs.promtail.log_level
      log_format                        = var.configs.promtail.log_format
      promtail_extra_scrape_configs     = local.extra_scrape_configs_yaml
      promtail_extra_label_configs_yaml = local.extra_relabel_configs_yaml
      promtail_extra_label_configs_raw  = local.extra_relabel_configs
      promtail_extra_pipeline_stages    = local.extra_pipeline_stages_yaml
      promtail_clients                  = try(var.configs.promtails.clients, ["http://${var.release_name}:3100/loki/api/v1/push"])
      promtail_server_port              = var.configs.promtail.server_port
      }
    )
  ]
}

resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}
