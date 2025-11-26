module "base" {
  source = "../../base"

  name = "Memory (${var.ingress_type})"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period
  defaults    = {}

  options = {
    legend = {
      show_legend = false
    }
  }
  unit = "bytes"

  metrics = [
    { label : "__auto", expression : "container_memory_working_set_bytes{pod=~\"(.+-)?${var.pod}(-[^-]+)?-[^-]+$\", namespace=\"${var.namespace}\"}" },
  ]
}
