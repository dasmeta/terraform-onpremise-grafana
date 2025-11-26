module "base" {
  source = "../../base"

  name = "Network Traffic"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period
  unit        = "bytes"

  metrics = concat([
    { label = "Received", expression = "sum(rate(container_network_receive_bytes_total{namespace=\"${var.namespace}\", pod=~\"^${var.container}-[^-]+-[^-]+$\"}[${var.period}]))" },
    { label = "Sent", expression = "- sum(rate(container_network_transmit_bytes_total{namespace=\"${var.namespace}\", pod=~\"^${var.container}-[^-]+-[^-]+$\"}[${var.period}]))" },
    { label = "Received ({{pod}})", color = "3ECE76", expression = "sum(rate(container_network_receive_bytes_total{namespace=\"${var.namespace}\", pod=~\"^${var.container}-[^-]+-[^-]+$\"}[${var.period}])) by (pod)" },
    { label = "Sent ({{pod}})", color = "FF0F3C", expression = "- sum(rate(container_network_transmit_bytes_total{namespace=\"${var.namespace}\", pod=~\"^${var.container}-[^-]+-[^-]+$\"}[${var.period}])) by (pod)" },
    ],
    var.host != null ? [{ label = "In(ingress)", expression = "sum(rate(nginx_ingress_controller_bytes_sent_bucket{host=\"${var.host}\"}[${var.period}]))" }] : [],
  )
}
