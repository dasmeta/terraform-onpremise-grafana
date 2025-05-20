module "base" {
  source = "../../base"

  name = "CPU (${var.ingress_type}) [${var.period}m]"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  defaults = {
    MetricNamespace = "ContainerInsights"
  }

  options = {
    legend = {
      show_legend = false
    }
  }

  unit = "percent"

  metrics = [
    { label : "__auto", expression : "rate(container_cpu_usage_seconds_total{pod=~\"${var.pod}-[^-]+-[^-]+$\", namespace=\"${var.namespace}\"}[$__rate_interval]) * 100" },
  ]
}
