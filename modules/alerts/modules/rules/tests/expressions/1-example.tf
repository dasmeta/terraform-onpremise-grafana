module "this" {
  source = "../../"

  alert_rules = [
    {
      name        = "Nginx Expressions"
      folder_name = "Nginx Expressions Group"
      datasource  = "prometheus"
      expr        = "sum(rate(nginx_ingress_controller_requests{status=~'5..'}[1m])) by (ingress,cluster) / sum(rate(nginx_ingress_controller_requests[1m]))by (ingress) * 100 > 5"
      function    = "mean"
      equation    = "gt"
      threshold   = 2
    },
    {
      name           = "Nginx Expressions"
      folder_name    = "Nginx Expressions Group"
      no_data_state  = "OK"
      exec_err_state = "OK"
      datasource     = "prometheus"
      expr           = "(sum(rate(nginx_ingress_controller_requests{status=~'4..'}[1m])) by (ingress) / sum(rate(nginx_ingress_controller_requests[1m])) by (ingress)) * 100 > 5"
      function       = "mean"
      equation       = "gt"
      threshold      = 2
    }
  ]
}
