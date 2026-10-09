module "base" {
  source = "../../base"

  name = "Connect totals by state"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period
  metrics = [
    { label = "connectors {{state}}", expression = "sum by (state) (kafka_connect_connectors${local.selector})" },
    { label = "tasks {{state}}", expression = "sum by (state) (kafka_connect_tasks${local.selector})" },
  ]
}
