module "base" {
  source = "../../base"

  name = "Consumer group members"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period
  metrics = [
    { label = "{{consumergroup}}", expression = "sum by (consumergroup) (kafka_consumergroup_members${local.selector})" },
  ]
}
