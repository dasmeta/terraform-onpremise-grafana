module "base" {
  source = "../../base"

  name = "Replicas"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period

  defaults = {
    MetricNamespace = "ContainerInsights"
    Namespace       = var.namespace
    PodName         = var.container
  }

  metrics = [
    { label = "Total", expression = "sum(kube_pod_status_phase{namespace=\"${var.namespace}\", pod=~\"${var.container}-.*\"})" },
    { label = "Running", expression = "sum(kube_pod_container_status_running{namespace=\"${var.namespace}\", pod=~\"${var.container}-.*\"})" },
    { label = "Terminated", expression = "sum(kube_pod_container_status_terminated{namespace=\"${var.namespace}\", pod=~\"${var.container}-.*\"})" },
    { label = "Waiting", expression = "sum(kube_pod_container_status_waiting{namespace=\"${var.namespace}\", pod=~\"${var.container}-.*\"})" },
  ]
}
