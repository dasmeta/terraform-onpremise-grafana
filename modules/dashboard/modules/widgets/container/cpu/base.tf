module "base" {
  source = "../../base"

  name = "CPU"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period

  defaults = {
    Namespace = var.namespace
    PodName   = var.container
  }

  metrics = var.by_pod ? [
    { label = "__auto", color = "FFC300", expression = "avg(rate(container_cpu_usage_seconds_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}])) by (pod)" },
    { label = "__auto", color = "FF774D", expression = "max(rate(container_cpu_usage_seconds_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}])) by (pod)" },
    { label = "Request", color = "007CEF", expression = "avg(kube_pod_container_resource_requests{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"cpu\"})" },
    { label = "Limit", color = "FF0F3C", expression = "avg(kube_pod_container_resource_limits{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"cpu\"})" },
    ] : [
    { label = "Avg", color = "FFC300", expression = "avg(rate(container_cpu_usage_seconds_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}]))" },
    { label = "Max", color = "FF774D", expression = "max(rate(container_cpu_usage_seconds_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}]))" },
    { label = "Request", color = "007CEF", expression = "max(kube_pod_container_resource_requests{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"cpu\"})" },
    { label = "Limit", color = "FF0F3C", expression = "max(kube_pod_container_resource_limits{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"cpu\"})" },

    { label = "Avg({{pod}})", expression = "avg(rate(container_cpu_usage_seconds_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}])) by (pod)" },
    { label = "Max({{pod}})", expression = "max(rate(container_cpu_usage_seconds_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}])) by (pod)" },
  ]
}
