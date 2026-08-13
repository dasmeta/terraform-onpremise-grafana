module "this" {
  source = "../.."

  application_dashboard = [
    {
      name        = "Test-dashboard",
      folder_name = "Test-dashboard",
      alerts      = { enabled = true },
      rows : [
        { type : "block/service", name = "http-echo", alerts = { namespaces = var.environments } }
      ]
      data_source = {
        uid = "prometheus"
      }

      variables = [
        {
          "name" : "namespace",
          "options" : [for environment in var.environments : { "value" : environment }]
        }
      ]
    }
  ]

  alerts = {
    rules = [
      {
        datasource  = "prometheus",
        equation    = "gt",
        expr        = "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
        folder_name = "Nginx Alerts",
        function    = "mean",
        name        = "Latency P1",
        labels = {
          priority = "P1",
          # env      = "dev" # as we have env label commented out it will not route this custom alert to any env alert channel and will got to default/fallback contact point, if we need to route to specific env we can enable the env label
        },
        threshold      = 3,
        summary        = "custom alert for routing validation",
        no_data_state  = "OK",
        exec_err_state = "OK"
      },
    ]
    contact_points = {
      slack = [
        {
          name        = "Slack-dev"
          webhook_url = var.slack_webhook_url
          recipient   = "#test-webhooks-channel-dev"
        },
        {
          name        = "Slack-stage"
          webhook_url = var.slack_webhook_url
          recipient   = "#test-webhooks-channel-stage"
        },
        {
          name        = "Slack-prod"
          webhook_url = var.slack_webhook_url
          recipient   = "#test-webhooks-channel-prod"
        },
        {
          name        = "ops-fallback"
          webhook_url = var.slack_webhook_url
          recipient   = "#test-webhooks-channel"
        }
      ]
    }
    notifications = {
      contact_point = "ops-fallback"
      policies = [
        {
          contact_point = "Slack-dev"
          matchers = [{
            label = "env"
            match = "="
            value = "dev"
          }]
        },
        {
          contact_point = "Slack-stage"
          matchers = [{
            label = "env"
            match = "="
            value = "stage"
          }]
        },
        {
          contact_point = "Slack-prod"
          matchers = [{
            label = "env"
            match = "="
            value = "prod"
          }]
        }
      ]
    }
  }

  grafana = {
    resources = {
      requests = {
        cpu    = "500m"
        memory = "500Mi"
      }
    }
    ingress = {
      type        = "nginx"
      tls_enabled = false
      hosts       = [var.grafana_hostname]
    }
  }

  tempo = {
    enabled = false
  }

  loki_stack = {
    enabled = false
  }

  prometheus = {
    enabled      = true
    storage_size = "500Mi"
    extra_configs = {
      prometheus-node-exporter = { # we set this block configs to have the prometheus-node-exporter be run ok on Docker Desktop k8s, this is for this test/example only on local Docker Desktop k8s setup
        hostRootFsMount = {
          enabled = false
        }
      }
    }
  }

  grafana_admin_password = var.grafana_admin_password
}
