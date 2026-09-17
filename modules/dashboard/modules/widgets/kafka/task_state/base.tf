module "base" {
  source = "../../base"

  name = "Task state"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period
  metrics = [
    { label = "{{connector}}/{{task}} {{state}}", expression = "sum by (connector, task, state) (kafka_connect_task_state${local.selector})" },
  ]
}
