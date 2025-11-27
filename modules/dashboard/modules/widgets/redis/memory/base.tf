module "base" {
  source = "../../base"

  name        = "Memory Usage"
  data_source = var.data_source
  coordinates = var.coordinates
  period      = var.period

  type = "gauge"

  thresholds = {
    "mode" : "absolute",
    "steps" : [
      {
        "color" : "green",
        "value" : null
      },
      {
        "color" : "red",
        "value" : 80
      },
      {
        "color" : "#EAB839",
        "value" : 95
      }
    ]
  }

  color_mode = "thresholds"

  metrics = [
    { label = "__auto", expression = "sum(100 * (redis_memory_used_bytes{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}  / redis_memory_max_bytes{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}))" }
  ]
}
