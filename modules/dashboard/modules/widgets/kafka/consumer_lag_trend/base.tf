module "base" {
  source = "../../base"

  name = "Consumer lag trend"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period
  metrics = [
    { label = "{{consumergroup}}", expression = "sum by (consumergroup) (increase(kafka_consumergroup_lag${local.selector}[${var.period}]))" },
    { label = "{{consumergroup}}/{{topic}} lag sum", expression = "sum by (consumergroup, topic) (kafka_consumergroup_lag_sum${local.selector})" },
  ]
}
