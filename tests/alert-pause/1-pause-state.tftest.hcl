run "service_alert_defaults_can_pause_generated_rules" {
  command = plan

  module {
    source = "../../modules/dashboard/modules/alerts/block-service"
  }

  variables {
    name      = "example"
    namespace = "default"
    defaults = {
      enabled   = true
      is_paused = true
    }
  }

  assert {
    condition     = alltrue([for rule in output.alert_rules : rule.is_paused])
    error_message = "A service alert default must pause every generated Grafana rule."
  }
}
