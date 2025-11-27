module "base" {
  source = "../../base"

  name = "Network I/O Errors"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period
  unit        = "bytes"

  metrics = [
    { label = "Transmit/Out", expression = "sum(rate(container_network_transmit_errors_total{namespace=\"${var.namespace}\", pod=~\"^${var.pod}(-[^-]+)?-[^-]+$\"}[${var.period}]))" },
    { label = "Received/In", expression = "-sum(rate(container_network_receive_errors_total{namespace=\"${var.namespace}\", pod=~\"^${var.pod}(-[^-]+)?-[^-]+$\"}[${var.period}]))" },
    { label = "Transmit/Out ({{pod}})", expression = "sum(rate(container_network_transmit_errors_total{namespace=\"${var.namespace}\", pod=~\"^${var.pod}(-[^-]+)?-[^-]+$\"}[${var.period}])) by (pod)" },
    { label = "Received/In ({{pod}})", expression = "-sum(rate(container_network_receive_errors_total{namespace=\"${var.namespace}\", pod=~\"^${var.pod}(-[^-]+)?-[^-]+$\"}[${var.period}])) by (pod)" },
  ]
}
