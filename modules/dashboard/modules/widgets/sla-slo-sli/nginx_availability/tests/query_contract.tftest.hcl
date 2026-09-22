variables {
  coordinates = {
    x      = 0
    y      = 0
    width  = 6
    height = 4
  }
}

run "default_uptime_contract" {
  command = plan

  variables {
    period = "7d"
  }

  assert {
    condition     = output.data.targets[0].expr == "100 * sum(increase(nginx_ingress_controller_requests{status!~\"5..\"}[7d])) / sum(increase(nginx_ingress_controller_requests{}[7d]))"
    error_message = "Uptime must be non-5xx requests divided by all requests for the selected period."
  }

  assert {
    condition     = output.data.fieldConfig.defaults.unit == "percent" && output.data.title == "Availability (7d)"
    error_message = "Uptime must be displayed as a percentage and identify its selected period."
  }
}

run "filtered_uptime_contract" {
  command = plan

  variables {
    period = "6h"
    filter = "namespace=\"production\", ingress=~\"api|web\""
  }

  assert {
    condition     = output.data.targets[0].expr == "100 * sum(increase(nginx_ingress_controller_requests{status!~\"5..\", namespace=\"production\", ingress=~\"api|web\"}[6h])) / sum(increase(nginx_ingress_controller_requests{namespace=\"production\", ingress=~\"api|web\"}[6h]))"
    error_message = "The uptime scope must be applied consistently to successful and total traffic."
  }
}

run "status_distribution_uses_selected_period" {
  command = plan

  variables {
    histogram = true
    period    = "6h"
    filter    = "namespace=\"production\""
  }

  assert {
    condition     = output.data.targets[0].expr == "sum by (status) (increase(nginx_ingress_controller_requests{namespace=\"production\"}[6h]))"
    error_message = "The status distribution must honor the selected period."
  }
}
