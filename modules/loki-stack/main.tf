resource "helm_release" "loki" {
  chart            = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  name             = var.configs.loki.release_name
  namespace        = var.namespace
  create_namespace = var.create_namespace
  version          = var.configs.loki.chart_version
  timeout          = 600

  values = [jsonencode(local.effective_values)]
}

# TODO: the promtail deprecated, consider to have this replaced with for example fluent/fluent-bit
resource "helm_release" "promtail" {
  count = var.configs.promtail.enabled ? 1 : 0

  chart            = "promtail"
  repository       = "https://grafana.github.io/helm-charts"
  name             = "${var.configs.loki.release_name}-promtail"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  version          = var.configs.promtail.chart_version
  timeout          = 300

  values = [
    templatefile("${path.module}/values/promtail-values.tpl", {
      promtail_log_level                = var.configs.promtail.log_level
      log_format                        = var.configs.promtail.log_format
      promtail_extra_scrape_configs     = local.extra_scrape_configs_yaml
      promtail_extra_label_configs_yaml = local.extra_relabel_configs_yaml
      promtail_extra_label_configs_raw  = local.extra_relabel_configs
      promtail_extra_pipeline_stages    = local.extra_pipeline_stages_yaml
      promtail_clients                  = local.promtail_clients
      promtail_server_port              = var.configs.promtail.server_port
      }
    ),
    jsonencode(var.configs.promtail.extra_configs)
  ]
}

resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}
