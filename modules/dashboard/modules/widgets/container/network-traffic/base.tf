locals {
  pod_matcher = var.legacy_dashboard_queries ? "^${var.pod}(-[^-]+)?-[^-]+$" : "^${var.pod}(-(primary|canary))?(-[^-]+)?-[^-]+$"
}

module "base" {
  source = "../../base"

  name = "Network Traffic (${var.ingress_type})"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period

  fillOpacity = 20
  unit        = "bytes"

  metrics = [
    { label : "Received", color : "7AAFF9", expression : "sum(rate(container_network_receive_bytes_total{namespace=\"${var.namespace}\", pod=~\"${local.pod_matcher}\"}[${var.period}]))" },
    { label : "Sent", color : "EF8BBE", expression : "- sum(rate(container_network_transmit_bytes_total{namespace=\"${var.namespace}\", pod=~\"${local.pod_matcher}\"}[${var.period}]))" },
  ]
}
