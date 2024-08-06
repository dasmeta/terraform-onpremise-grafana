module "base" {
  source = "../../base"

  name              = "Network In/Out [${var.period}m]"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  defaults = {
    MetricNamespace = "ContainerInsights"
    ClusterName     = var.cluster
    Namespace       = var.namespace
    PodName         = var.container
    accountId       = var.account_id
  }


  metrics = concat([
    { label = "In(container)", expression = "sum(rate(container_network_receive_bytes_total{namespace=\"${var.namespace}\", pod=~\"${var.container}-.*\"} [${var.period}m])) / 100000" },
    { label = "Out(container)", expression = "sum(rate(container_network_transmit_bytes_total{namespace=\"${var.namespace}\", pod=~\"${var.container}-.*\"} [${var.period}m])) / 100000" },
    ],
    var.host != null ? [{ label = "In(ingress)", expression = "sum(rate(nginx_ingress_controller_bytes_sent_bucket{host=\"${var.host}\"}[${var.period}m]))" }] : [],
  )
}
