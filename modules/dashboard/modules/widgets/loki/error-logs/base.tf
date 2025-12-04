module "base" {
  source = "../../base"

  name = "Error logs (${var.direction} ${var.limit} items)"
  data_source = {
    uid  = var.datasource_uid
    type = "loki"
  }

  type        = "logs"
  coordinates = var.coordinates
  period      = var.period

  loki_targets = [
    { label = "Errors in logs", direction = var.direction, limit = var.limit, expr = var.expr == "" ? "{namespace=\"${var.namespace}\", pod=~\"${var.deployment}.*\"}${var.parser != "" ? " | ${var.parser}" : ""}${var.filter != "" ? " | ${var.filter}" : ""}" : var.expr }
  ]
}
