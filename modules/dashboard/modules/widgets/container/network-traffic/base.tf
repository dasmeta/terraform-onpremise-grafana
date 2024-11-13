module "base" {
  source = "../../base"

  name              = "Network Traffic (${var.ingress_type}) [${var.period}m]"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  defaults = {
    MetricNamespace = "ContainerInsights"
    accountId       = var.account_id
  }

  fillOpacity = 20
  unit        = "bytes"

  metrics = [
    { label : "Received", color : "7AAFF9", expression : "sum(rate(container_network_receive_bytes_total{pod=~\"^${var.pod}-[^-]+-[^-]+$\"}[$__rate_interval]))" },
    { label : "Sent", color : "EF8BBE", expression : "- sum(rate(container_network_transmit_bytes_total{pod=~\"^${var.pod}-[^-]+-[^-]+$\"}[$__rate_interval]))" },
  ]
}
