resource "helm_release" "loki" {
  chart      = "loki-stack"
  repository = "https://grafana.github.io/helm-charts"
  name       = var.release_name
  namespace  = var.namespace
  version    = var.chart_version

  values = [
    templatefile("${path.module}/values/loki-values.yaml.tpl", {
      loki_url             = var.configs.loki.url == "" ? "http://${var.release_name}:3100" : var.configs.loki.url
      promtail_enabled     = var.configs.promtail.enabled
      promtail_log_level   = var.configs.promtail.log_level
      promtail_clients     = try(var.configs.promtails.clients, ["http://${var.release_name}:3100/loki/api/v1/push"])
      promtail_server_port = var.configs.promtail.server_port
      enabled_fluentbit    = var.configs.fluentbit_enabled
      enabled_test_pod     = var.configs.enable_test_pod
      }
    )
  ]
}
