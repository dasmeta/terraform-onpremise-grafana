run "default_alert_contract" {
  command = plan

  assert {
    condition     = length(output.alert_rules) == 2
    error_message = "Both SLA alerts must remain enabled by default."
  }

  assert {
    condition     = output.alert_rules[0].expr == "(sum(rate(nginx_ingress_controller_request_duration_seconds_sum{status=~\"2..|3..\"}[5m])) / sum(rate(nginx_ingress_controller_request_duration_seconds_count{status=~\"2..|3..\"}[5m]))) unless sum(rate(nginx_ingress_controller_request_duration_seconds_count{status=~\"2..|3..\"}[5m])) == 0"
    error_message = "The latency alert must use the aggregate successful-request weighted mean."
  }

  assert {
    condition     = output.alert_rules[1].expr == "(100 * sum(rate(nginx_ingress_controller_requests{status!~\"5..\"}[5m])) / sum(rate(nginx_ingress_controller_requests{}[5m]))) unless sum(rate(nginx_ingress_controller_requests{}[5m])) == 0"
    error_message = "The availability alert must use non-5xx requests divided by all requests."
  }

  assert {
    condition     = output.alert_rules[0].annotations.threshold == 2 && output.alert_rules[0].annotations.metric == "request_latency_seconds"
    error_message = "The latency alert must publish its own seconds threshold and metric annotation."
  }

  assert {
    condition     = output.alert_rules[1].annotations.threshold == 99 && output.alert_rules[1].annotations.impact == "Service might be unavailable"
    error_message = "The availability alert must publish its own threshold and impact."
  }
}

run "filtered_alert_contract" {
  command = plan

  variables {
    alerts = {
      latency = {
        metric_filter = "namespace=\"production\", ingress=~\"api|web\""
        annotations   = { runbook = "https://runbooks.example.com/latency" }
      }
      availability = {
        enabled = false
      }
    }
  }

  assert {
    condition     = length(output.alert_rules) == 1
    error_message = "The filtered test must produce only the latency alert."
  }

  assert {
    condition     = output.alert_rules[0].expr == "(sum(rate(nginx_ingress_controller_request_duration_seconds_sum{status=~\"2..|3..\", namespace=\"production\", ingress=~\"api|web\"}[5m])) / sum(rate(nginx_ingress_controller_request_duration_seconds_count{status=~\"2..|3..\", namespace=\"production\", ingress=~\"api|web\"}[5m]))) unless sum(rate(nginx_ingress_controller_request_duration_seconds_count{status=~\"2..|3..\", namespace=\"production\", ingress=~\"api|web\"}[5m])) == 0"
    error_message = "The alert scope must be applied consistently without a dangling separator."
  }

  assert {
    condition     = output.alert_rules[0].annotations.runbook == "https://runbooks.example.com/latency"
    error_message = "Latency annotations must come from the latency alert configuration."
  }
}
