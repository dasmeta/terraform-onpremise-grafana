module "this" {
  source = "../.."

  datasource = "victoriametrics"
  name       = "teamplus-main-web"
  namespace  = "teamplus"

  defaults = {
    workload_suffix = "-primary"
  }
}

output "alert_rules_json" {
  value = jsonencode(module.this.alert_rules)
}
