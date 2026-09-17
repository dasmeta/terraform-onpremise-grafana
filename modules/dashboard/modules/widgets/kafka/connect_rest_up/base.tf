module "base" {
  source = "../../base"

  name = "Kafka Connect REST"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period
  type        = "stat"

  metrics = [
    { label = "REST up", color = "37872D", expression = "sum(kafka_connect_rest_up${local.selector})" },
  ]
}
