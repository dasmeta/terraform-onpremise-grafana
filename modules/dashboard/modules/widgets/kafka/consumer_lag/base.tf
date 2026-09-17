module "base" {
  source = "../../base"

  name = "Consumer lag"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period
  metrics = [
    { label = "{{consumergroup}}/{{topic}} lag", expression = "sum by (consumergroup, topic) (kafka_consumergroup_lag${local.selector})" },
    { label = "{{consumergroup}}/{{topic}} offset", expression = "sum by (consumergroup, topic) (kafka_consumergroup_current_offset_sum${local.selector})" },
  ]
}
