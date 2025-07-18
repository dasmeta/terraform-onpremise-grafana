module "base" {
  source = "../../base"

  name = "Errors"
  data_source = {
    uid  = var.datasource_uid
    type = "loki"
  }

  type        = "logs"
  coordinates = var.coordinates
  period      = var.period

  loki_targets = [
    { label = "Errors or Warns in logs", legend_format = "Errors deployment", expr = var.expr == "" ? "{pod=~\"${var.deployment}.*\"} | logfmt | level=\"warn\" or level=\"error\"" : var.expr }
  ]
}
