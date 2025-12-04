module "base" {
  source = "../../base"

  name = "CPU (${var.ingress_type})"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period

  options = {
    legend = {
      show_legend = false
    }
  }
  unit = "s"

  metrics = [
    # { label : "__auto", expression : "rate(container_cpu_usage_seconds_total{pod=~\"(.+-)?${var.pod}(-[^-]+)?-[^-]+$\", namespace=\"${var.namespace}\"}[${var.period}]) * 100" },

    { label = "Avg", color = "FFC300", expression = "avg(rate(container_cpu_usage_seconds_total{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\"}[${var.period}]))" },
    { label = "Max", color = "FF774D", expression = "max(rate(container_cpu_usage_seconds_total{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\"}[${var.period}]))" },
    { label = "Request", color = "007CEF", expression = "max(kube_pod_container_resource_requests{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\", resource=\"cpu\"})" },
    { label = "Limit", color = "FF0F3C", expression = "max(kube_pod_container_resource_limits{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\", resource=\"cpu\"})" },

    { label = "Avg({{pod}})", expression = "avg(rate(container_cpu_usage_seconds_total{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\"}[${var.period}])) by (pod)" },
    { label = "Max({{pod}})", expression = "max(rate(container_cpu_usage_seconds_total{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\"}[${var.period}])) by (pod)" },
  ]
}
