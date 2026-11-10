mock_provider "grafana" {}
mock_provider "helm" {}
mock_provider "random" {}
mock_provider "time" {}

run "accepts_mixed_dashboard_rows" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    application_dashboard = [
      {
        name     = "mixed-dashboard"
        defaults = { period = "1d" }
        rows = [
          {
            type      = "block/service"
            name      = "worker"
            namespace = "example"
            alerts    = { enabled = false }
          },
          {
            type           = "block/aws-ses"
            block_name     = "Email"
            region         = "eu-central-1"
            datasource_uid = "cloudwatch"
            max            = 100
          },
        ]
      },
      {
        name = "secondary-dashboard"
        rows = [
          {
            type             = "block/sla"
            name             = ""
            namespace        = "example"
            period           = "1d"
            sla_ingress_type = "nginx"
            datasource_uid   = "prometheus"
            alerts           = { enabled = false }
          },
        ]
      },
    ]
    grafana          = { enabled = false }
    prometheus       = { enabled = true }
    victoria_metrics = { enabled = false }
    tempo            = { enabled = false }
    loki_stack       = { enabled = false }
    alerts = {
      disk_capacity  = { enabled = false }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }
}
