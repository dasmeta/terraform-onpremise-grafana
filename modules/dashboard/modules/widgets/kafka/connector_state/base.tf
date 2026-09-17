module "base" {
  source = "../../base"

  name = "Connector state"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period
  metrics = [
    { label = "{{connector}} {{state}}", expression = "sum by (connector, state) (kafka_connect_connector_state${local.selector})" },
  ]
}
