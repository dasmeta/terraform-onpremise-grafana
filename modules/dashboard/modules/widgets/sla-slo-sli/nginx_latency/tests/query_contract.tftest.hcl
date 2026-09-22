variables {
  coordinates = {
    x      = 0
    y      = 0
    width  = 6
    height = 4
  }
}

run "default_average_latency_contract" {
  command = plan

  variables {
    period = "7d"
  }

  assert {
    condition     = output.data.targets[0].expr == "sum(increase(nginx_ingress_controller_request_duration_seconds_sum{status=~\"2..|3..\"}[7d])) / sum(increase(nginx_ingress_controller_request_duration_seconds_count{status=~\"2..|3..\"}[7d]))"
    error_message = "Latency must be the request-weighted mean duration for 2xx and 3xx responses."
  }

  assert {
    condition     = output.data.fieldConfig.defaults.unit == "s" && output.data.title == "Latency (7d)"
    error_message = "Average latency must be displayed in seconds and identify its selected period."
  }

  assert {
    condition = (
      length(output.data.fieldConfig.defaults.thresholds.steps) == 4 &&
      output.data.fieldConfig.defaults.thresholds.steps[0].value == null &&
      output.data.fieldConfig.defaults.thresholds.steps[0].color == "green" &&
      output.data.fieldConfig.defaults.thresholds.steps[1].value == 2 &&
      output.data.fieldConfig.defaults.thresholds.steps[2].value == 2.5 &&
      output.data.fieldConfig.defaults.thresholds.steps[3].value == 3
    )
    error_message = "Latency thresholds must be absolute seconds rather than percentages."
  }
}

run "filtered_average_latency_contract" {
  command = plan

  variables {
    period = "6h"
    filter = "namespace=\"production\", ingress=~\"api|web\""
  }

  assert {
    condition     = output.data.targets[0].expr == "sum(increase(nginx_ingress_controller_request_duration_seconds_sum{status=~\"2..|3..\", namespace=\"production\", ingress=~\"api|web\"}[6h])) / sum(increase(nginx_ingress_controller_request_duration_seconds_count{status=~\"2..|3..\", namespace=\"production\", ingress=~\"api|web\"}[6h]))"
    error_message = "The latency scope must be applied consistently to duration and request count."
  }
}

run "latency_distribution_uses_successful_requests_and_period" {
  command = plan

  variables {
    histogram = true
    period    = "6h"
    filter    = "namespace=\"production\""
  }

  assert {
    condition     = output.data.targets[0].expr == "sum by (le) (increase(nginx_ingress_controller_request_duration_seconds_bucket{status=~\"2..|3..\", namespace=\"production\"}[6h]))"
    error_message = "Latency distribution must use successful responses and the selected period."
  }
}
