module "base" {
  source = "../../base"

  name = "Memory (${var.ingress_type}) [${var.period}m]"
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

  unit = "bytes"

  metrics = [
    { label : "__auto", expression : "container_memory_working_set_bytes{pod=~\"${var.pod}-[^-]+-[^-]+$\", namespace=\"${var.namespace}\"}" },
  ]
}
