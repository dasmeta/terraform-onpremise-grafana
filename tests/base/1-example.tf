module "this" {
  source = "../.."

  name = "Test-dashboard"

  application_dashboard = {
    rows : [
      { type : "block/sla" },
      { type : "block/ingress" },
      { type : "block/service", name : "backend", host : "api.dev.trysela.com" },
      { type : "block/service", name : "worker" },
      { type : "block/service", name : "talk" }
    ]
    data_source = {
      uid : "PBFA97CFB590B2093"
    }
    variables = [
      {
        "name" : "namespace",
        "options" : [
          {
            "selected" : true,
            "value" : "prod"
          },
          {
            "value" : "dev"
          }
        ],
      }
    ]
  }

  alerts = {
    rules = [
      {
        "datasource" : "prometheus",
        "equation" : "gt",
        "expr" : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
        "folder_name" : "Nginx Alerts",
        "function" : "mean",
        "name" : "Latency P1",
        "labels" : {
          "priority" : "P1",
        }
        "threshold" : 3

        # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
        "no_data_state" : "OK"
        "exec_err_state" : "OK"
        # "exec_err_state" : "Alerting" # uncomment to trigger new alert
      },
      {
        "datasource" : "prometheus",
        "equation" : "gt",
        "expr" : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
        "folder_name" : "Nginx Alerts",
        "function" : "mean",
        "name" : "Latency P2",
        "labels" : {
          "priority" : "P2",
        }
        "threshold" : 3

        # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
        "no_data_state" : "OK"
        "exec_err_state" : "OK"
        # "exec_err_state" : "Alerting" # uncomment to trigger new alert
      }
    ]
  }
}
