module "this" {
  source = "../.."

  ## NOTE: this may reset and/or duplicate your manually created contact_points/notification_policies so make sure you check/test things after apply
  alerts = {
    contact_points = {
      slack = [
        {
          name        = "slack"
          webhook_url = "https://hooks.slack.com/services/xxxx/yyyyyy/zzzzzzzz" # secret value
        }
      ]
      ## to enable opsgenie contact point
      # opsgenie = [
      #   {
      #     name       = "OpsGenie"
      #     api_key    = "{opsgenie-integration-api-key}" # secret value
      #     auto_close = true
      #   }
      # ]
      webhook = [ # here we create CB as notification channel
        {
          name = "cb"
          url  = "https://n8n.dasmeta.com/webhook/<n8n-webhook-trigger-id>?accountId=<accountId-in-cloudbrowser>" # secret value
        }
      ]
    }
    notifications = {
      contact_point   = "slack" # default contact point if no policies defied (NOTE: if you have items in policies field this will be ignored and you have to have slack in policies list also to send notifications to slack)
      group_interval  = "1m"    # for testing we set this low values, in real setup remove this line to use default
      repeat_interval = "1m"    # for testing we set this low values, in real setup remove this line to use default

      ## to sent all alerts to slack and CB webhook
      policies = [
        # P1 priority alerts to opsgenie and
        # {
        #   contact_point = "opsgenie"
        #   matchers      = [{ label = "priority", match = "=", value = "P1" }]
        # },
        {
          contact_point = "slack" # we have to enable slack here even if we have slack as default channel as we have other channels in policies
        },
        {
          contact_point = "cb" # here we enable CB notification channel
        }
      ]
    }
    rules = [
      {
        "datasource" : "prometheus",
        "equation" : "gt",
        "expr" : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
        "function" : "mean",
        "name" : "Latency P2",
        "labels" : {
          "priority" : "P2",
        }
        "filters" : {}
        "threshold" : 5 # ti fire alert you can decrease the threshold to 0 or if no-data just comment out bellow line for no_data_state

        # set/uncomment this if you want to have no data treated as ok, this can be handy to test in grafana setup when the metric we created alert on not available
        # "no_data_state" : "OK"
      }
    ]
  }

  # for this test/example we disable all other components
  grafana = {
    enabled = false
  }

  tempo = {
    enabled = false
  }

  loki_stack = {
    enabled = false
  }

  prometheus = {
    enabled = false
  }
}
