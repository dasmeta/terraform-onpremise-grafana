module "base" {
  source = "../../base"

  name = "Warns"
  data_source = {
    uid  = var.datasource_uid
    type = "loki"
  }

  type        = "logs"
  coordinates = var.coordinates
  period      = var.period
  loki_targets = [
    { label = "Warns in logs", legend_format = "Warns deployment", expr = var.expr == "" ? "{pod=~\"${var.deployment}.*\"} | logfmt | level=\"warn\"" : var.expr }
  ]
}
