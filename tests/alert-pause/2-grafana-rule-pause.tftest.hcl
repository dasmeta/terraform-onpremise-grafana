mock_provider "grafana" {}

run "generic_rules_pass_pause_state_to_grafana" {
  command = plan

  module {
    source = "../../modules/alerts/modules/rules"
  }

  variables {
    folder_name_uids = {
      alerts = "alerts-folder"
    }
    alert_rules = [
      {
        name       = "example paused rule"
        datasource = "prometheus"
        expr       = "vector(1)"
        condition  = "$B > 0"
        group      = "example"
        is_paused  = true
      }
    ]
  }

  assert {
    condition     = grafana_rule_group.this["example"].rule[0].is_paused
    error_message = "The generic Grafana rule module must pass is_paused to Grafana."
  }
}
