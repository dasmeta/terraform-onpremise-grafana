module "base" {
  source = "../../base"

  name = "Network I/O Errors [${var.period}m]"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period

  defaults = {
    MetricNamespace = "ContainerInsights"
  }

  options = {
    legend = {
      show_legend = false
    }
  }

  metrics = [
    { label : "Transmit(Out) network Errors", color : "FF103B", expression : "rate(container_network_transmit_errors_total{namespace=\"${var.namespace}\", pod=~\"^${var.pod}(-[^-]+)?-[^-]+$\"}[${var.period}m])" },
    { label : "Received(In) network Errors", color : "FA7551", expression : "rate(container_network_receive_errors_total{namespace=\"${var.namespace}\", pod=~\"^${var.pod}(-[^-]+)?-[^-]+$\"}[${var.period}m])" },
  ]
}
