module "base" {
  source = "../../base"

  name = "Count of logs(Total,Errors,Warns)"
  data_source = {
    uid  = var.datasource_uid
    type = "loki"
  }
  unit = "ops"

  type        = "timeseries"
  coordinates = var.coordinates

  loki_targets = [
    { label = "Total", expr = "sum(rate({namespace=\"${var.namespace}\", pod=~\"${var.deployment}.*\"}[${var.period}]))" },
    { label = "Errors", expr = "sum(rate({namespace=\"${var.namespace}\", pod=~\"${var.deployment}.*\"}${var.parser != "" ? " | ${var.parser}" : ""}${var.error_filter != "" ? " | ${var.error_filter}" : ""}[${var.period}]))" },
    { label = "Warns", expr = "sum(rate({namespace=\"${var.namespace}\", pod=~\"${var.deployment}.*\"}${var.parser != "" ? " | ${var.parser}" : ""}${var.warn_filter != "" ? " | ${var.warn_filter}" : ""}[${var.period}]))" },
  ]
}
