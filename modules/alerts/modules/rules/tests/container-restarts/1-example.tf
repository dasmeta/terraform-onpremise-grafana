module "this" {
  source = "../../"

  alert_rules = [
    {
      name            = "App_1 has too many restarts"
      summary         = "App_1 microservice has too many restarts"
      folder_name     = "Restarts"
      datasource      = "prometheus"
      metric_name     = "kube_pod_container_status_restarts_total"
      metric_function = "rate"
      metric_interval = "[5m]"
      filters = {
        container = "app-1-container"
      }
      function  = "mean"
      equation  = "gt"
      threshold = 2
    },
    {
      name            = "App_2 has too many restarts"
      folder_name     = "Restarts"
      datasource      = "prometheus"
      metric_name     = "kube_pod_container_status_restarts_total"
      metric_function = "rate"
      metric_interval = "[5m]"
      filters = {
        container = "app-2-container"
      }
      function  = "mean"
      equation  = "gte"
      threshold = 4
    }
  ]
}
