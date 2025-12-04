module "base" {
  source = "../../base"

  name = "Memory (${var.ingress_type})"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  options = {
    legend = {
      show_legend = false
    }
  }
  unit = "bytes"

  metrics = [
    # { label : "__auto", expression : "container_memory_working_set_bytes{pod=~\"(.+-)?${var.pod}(-[^-]+)?-[^-]+$\", namespace=\"${var.namespace}\"}" },
    { label = "Avg", color = "FFC300", expression = "avg(container_memory_usage_bytes{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\"})" },
    { label = "Max", color = "FF774D", expression = "max(container_memory_usage_bytes{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\"})" },
    { label = "Request", color = "007CEF", expression = "avg(kube_pod_container_resource_requests{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\", resource=\"memory\"})" },
    { label = "Limit", color = "FF0F3C", expression = "avg(kube_pod_container_resource_limits{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\", resource=\"memory\"})" },
    { label = "Avg({{pod}})", color = "FFC300", expression = "avg(container_memory_usage_bytes{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\"}) by (pod)" },
    { label = "Max({{pod}})", color = "FF774D", expression = "max(container_memory_usage_bytes{pod=~'(.+-)?${var.pod}(-[^-]+)?-[^-]+$', namespace=\"${var.namespace}\"}) by (pod)" },
  ]
}
