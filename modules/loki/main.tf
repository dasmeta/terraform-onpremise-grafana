resource "helm_release" "loki" {
  chart            = "loki-stack"
  repository       = "https://grafana.github.io/helm-charts"
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version

  values = [
    templatefile("${path.module}/values/loki-values.yaml.tpl", {
      loki_url                          = var.configs.loki.url == "" ? "http://${var.release_name}:3100" : var.configs.loki.url
      volume_enabled                    = var.configs.loki.volume_enabled
      promtail_enabled                  = var.configs.promtail.enabled
      promtail_log_level                = var.configs.promtail.log_level
      log_format                        = var.configs.promtail.log_format
      promtail_extra_scrape_configs     = local.extra_scrape_configs_yaml
      promtail_extra_label_configs_yaml = local.extra_relabel_configs_yaml
      promtail_extra_label_configs_raw  = local.extra_relabel_configs
      promtail_clients                  = try(var.configs.promtails.clients, ["http://${var.release_name}:3100/loki/api/v1/push"])
      promtail_server_port              = var.configs.promtail.server_port
      enabled_fluentbit                 = var.configs.fluentbit_enabled
      enabled_test_pod                  = var.configs.enable_test_pod
      }
    )
  ]
}
