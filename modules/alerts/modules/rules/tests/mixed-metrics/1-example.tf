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
      name            = "App_2 max autoscaling"
      summary         = "App_2 microservice has been using max replicas for 1 hour"
      folder_name     = "Autoscaling"
      datasource      = "prometheus"
      metric_name     = "kube_deployment_status_replicas_available"
      metric_function = "rate"
      metric_interval = "[1h]"
      filters = {
        deployment = "app-2-microservice"
      }
      function  = "mean"
      equation  = "gte"
      threshold = 20
    },
    {
      name        = "App_1 has 0 available replicas"
      folder_name = "Replica Count"
      datasource  = "prometheus"
      metric_name = "kube_deployment_status_replicas_available"
      filters = {
        deployment = "app-1-microservice"
      }
      function  = "mean"
      equation  = "lt"
      threshold = 1
    },
    {
      name            = "Maximum node utilization in cluster"
      summary         = "Cluster is using 8 available nodes"
      folder_name     = "Node Autoscaling"
      datasource      = "prometheus"
      filters         = null
      metric_name     = "kube_node_info"
      metric_function = "sum"
      function        = "mean"
      equation        = "gte"
      threshold       = 8
    }
  ]
}
