module "base" {
  source = "../../base"

  name = "Network Traffic (${var.ingress_type}) [${var.period}m]"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period

  defaults = {
    MetricNamespace = "ContainerInsights"
  }

  fillOpacity = 20
  unit        = "bytes"

  metrics = [
    { label : "Received", color : "7AAFF9", expression : "sum(rate(container_network_receive_bytes_total{pod=~\"^${var.pod}-[^-]+-[^-]+$\"}[$__rate_interval]))" },
    { label : "Sent", color : "EF8BBE", expression : "- sum(rate(container_network_transmit_bytes_total{pod=~\"^${var.pod}-[^-]+-[^-]+$\"}[$__rate_interval]))" },
  ]
}
