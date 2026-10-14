locals {
  pod_matcher = var.legacy_dashboard_queries ? "^${var.container}-[^-]+-[^-]+$" : "^${var.container}(-(primary|canary))?-[^-]+-[^-]+$"
}

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
    Namespace = var.namespace
    PodName   = var.container
  }

  metrics = [
    { label = "Total", expression = "sum(kube_pod_status_phase{namespace=\"${var.namespace}\", pod=~\"${local.pod_matcher}\"})" },
    { label = "{{phase}}", expression = "sum(kube_pod_status_phase{namespace=\"${var.namespace}\", pod=~\"${local.pod_matcher}\"}) by (phase)" },
    { label = "Restarts", expression = "sum(rate(kube_pod_container_status_restarts_total{namespace=\"${var.namespace}\", pod=~\"${local.pod_matcher}\"}[${var.period}])) by (container)" },
  ]
}
