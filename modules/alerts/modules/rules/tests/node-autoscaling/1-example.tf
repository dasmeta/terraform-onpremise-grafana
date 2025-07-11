module "this" {
  source = "../../"

  alert_rules = [
    {
      name            = "Maximum node utilization in cluster"
      summary         = "Cluster is using 8 available nodes"
      folder_name     = "Test"
      priority        = "P1"
      datasource      = "prometheus"
      filters         = null
      metric_name     = "kube_node_info"
      metric_function = "sum"
      function        = "mean"
      equation        = "gt"
      threshold       = "8"
    },
    {
      name        = "High node utilization in cluster"
      summary     = "Cluster is using 6 of the available 8 nodes"
      folder_name = "Test"
      datasource  = "prometheus"
      filters     = null
      metric_name = "kube_node_info"
      function    = "mean"
      equation    = "gt"
      threshold   = "6"
    },
    {
      name            = "Insufficient nodes in cluster"
      summary         = "Cluster is using fewer nodes than the required count"
      folder_name     = "Test"
      datasource      = "prometheus"
      filters         = null
      metric_name     = "kube_node_info"
      metric_function = "sum"
      function        = "mean"
      equation        = "lt"
      threshold       = "2"
    }
  ]
}
