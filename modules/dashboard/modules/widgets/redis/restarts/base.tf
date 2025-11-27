module "base" {
  source = "../../base"

  name              = "Restarts"
  data_source       = var.data_source
  coordinates       = var.coordinates
  stat              = "Maximum"
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  defaults = {
    MetricNamespace = "ContainerInsights"
    ClusterName     = var.cluster
    Namespace       = var.namespace
    PodName         = var.redis_pod
    accountId       = var.account_id
  }

  metrics = [
    { label = "Restarts", color = "d62728", expression = "sum(rate(kube_pod_container_status_restarts_total{pod=\"${var.redis_pod}\", namespace=\"${var.redis_namespace}\"}[${var.period}]))" },
  ]
}
