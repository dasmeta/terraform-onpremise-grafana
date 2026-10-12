# Configurable service-alert pause state

## Goal

Allow application-dashboard service alert rules to preserve or intentionally set their Grafana pause state from `alerts.defaults.is_paused`.

## Requirements

- `is_paused` is optional and defaults to `false`.
- A dashboard-level default reaches every generated `block/service` alert rule.
- Existing consumers that omit the setting retain their current unpaused behavior.
- The generic Grafana rule module passes the resolved value to `grafana_rule_group`.

## Acceptance criteria

- A service alert with `defaults.is_paused = true` produces only rules where `is_paused` is true.
- Existing monitoring scheduling tests remain green.
