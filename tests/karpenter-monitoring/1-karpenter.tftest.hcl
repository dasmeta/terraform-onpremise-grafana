mock_provider "grafana" {}
mock_provider "random" {}

variables {
  name             = "karpenter"
  folder_name      = "dashboards"
  folder_name_uids = { dashboards = "dashboard-folder" }
  data_source      = { uid = "prometheus", type = "prometheus" }
  rows = [
    {
      type          = "block/service"
      name          = "controller"
      workload_name = "karpenter"
      namespace     = "karpenter"
    },
    {
      type      = "block/karpenter"
      namespace = "karpenter"
    },
  ]
}

run "service_block_uses_workload_name_for_pods_and_name_for_container" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  assert {
    condition = alltrue([
      contains(flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, "")]]), "sum(kube_pod_status_phase{namespace=\"karpenter\", pod=~\"^karpenter(-(primary|canary))?-[^-]+-[^-]+$\"})"),
      length([for expr in flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, "")]]) : expr if strcontains(expr, "container_cpu_usage_seconds_total{container=\"controller\", namespace=\"karpenter\"}")]) > 0,
    ])
    error_message = "service block widgets must select pods by workload_name(karpenter) and containers by name(controller)"
  }

  assert {
    condition = alltrue([
      length([for rule in output.widget_alert_rules : rule if strcontains(try(rule.expr, ""), "kube_deployment_status_replicas_available{deployment='karpenter', namespace='karpenter'}")]) > 0,
      length([for rule in output.widget_alert_rules : rule if strcontains(try(rule.expr, ""), "container_cpu_usage_seconds_total{container='controller', namespace='karpenter'}")]) > 0,
      length([for rule in output.widget_alert_rules : rule if strcontains(try(rule.expr, ""), "container_memory_working_set_bytes{container='controller', namespace='karpenter'}")]) > 0,
    ])
    error_message = "service block alerts must use workload_name for workload queries and name for container queries"
  }
}

run "service_block_without_workload_name_is_unchanged" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    rows = [{ type = "block/service", name = "app", namespace = "prod" }]
  }

  assert {
    condition = alltrue([
      contains(flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, "")]]), "sum(kube_pod_status_phase{namespace=\"prod\", pod=~\"^app(-(primary|canary))?-[^-]+-[^-]+$\"})"),
      length([for rule in output.widget_alert_rules : rule if strcontains(try(rule.expr, ""), "kube_deployment_status_replicas_available{deployment='app', namespace='prod'}")]) > 0,
    ])
    error_message = "service block must keep using name for pods and workloads when workload_name is not set"
  }

  assert {
    condition     = alltrue([for rule in output.widget_alert_rules : rule.pending_period == null if strcontains(rule.name, "has too many restarts")])
    error_message = "restarts alert must keep firing on first evaluation when its pending_period is not set"
  }
}

run "karpenter_block_renders_drift_and_node_panels" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  assert {
    condition = alltrue([
      contains(flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, "")]]), "max by (name, karpenter_sh_nodepool) (operator_nodeclaim_status_condition_current_status_seconds{namespace=\"karpenter\",type=\"Drifted\",status=\"True\"})"),
      contains(flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, "")]]), "sum by (karpenter_sh_nodepool) (operator_nodeclaim_status_condition_count{namespace=\"karpenter\",type=\"Drifted\",status=\"True\"})"),
      contains(flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, "")]]), "count by (nodepool, capacity_type) (karpenter_nodes_allocatable{namespace=\"karpenter\",resource_type=\"cpu\",nodepool!=\"\"})"),
    ])
    error_message = "karpenter block must render drift and node panels"
  }

  assert {
    condition     = length([for panel in output.widget_result : panel if try(panel.title, "") == "Time in drifted state per node"]) == 1
    error_message = "drift duration panel must be rendered once"
  }

  assert {
    condition = alltrue([
      contains(flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, "")]]), "sum(operator_nodeclaim_status_condition_count{namespace=\"karpenter\",type=\"Drifted\",status=\"True\"}) or vector(0)"),
      # every karpenter metrics panel(except nodepool usage, where 0% would be misleading) has a 0 fallback line
      alltrue([for panel in output.widget_result : anytrue([for target in panel.targets : strcontains(target.expr, "or vector(0)")]) if panel.title != "Nodepool usage of limits" && (strcontains(jsonencode(try(panel.targets, [])), "karpenter_") || strcontains(jsonencode(try(panel.targets, [])), "operator_nodeclaim"))]),
    ])
    error_message = "karpenter panels must show 0 instead of no data on a quiet cluster"
  }

  assert {
    condition     = one([for panel in output.widget_result : panel.fieldConfig.defaults.noValue if try(panel.title, "") == "Nodepool usage of limits"]) == "No nodepool limits set"
    error_message = "nodepool usage panel must explain why it is empty instead of showing a misleading 0%"
  }

  assert {
    condition     = alltrue([for panel in output.widget_result : !can(panel.fieldConfig.defaults.noValue) if try(panel.title, "") != "Nodepool usage of limits"])
    error_message = "other panels must keep grafana default no value text, the base widget change must not touch them"
  }
}

run "drift_alert_fires_after_one_day_by_default" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  assert {
    condition = length([for rule in output.widget_alert_rules : rule if
      try(rule.expr, "") == "max by (name, karpenter_sh_nodepool) (operator_nodeclaim_status_condition_current_status_seconds{namespace=\"karpenter\",type=\"Drifted\",status=\"True\"}) / 3600"
      && rule.equation == "gt" && rule.threshold == 24 && rule.no_data_state == "OK"
    ]) == 1
    error_message = "drift alert must fire when a node is drifted for more than 24 hours and treat no data as OK"
  }

  assert {
    condition     = length([for rule in output.widget_alert_rules : rule if strcontains(try(rule.group, ""), "Karpenter")]) == 8
    error_message = "all karpenter alerts except the opt-in disruption_rate and interruption_not_handled must be enabled by default"
  }

  assert {
    condition     = alltrue([for rule in output.widget_alert_rules : rule.group == "Karpenter" && startswith(rule.name, "Karpenter: ") && !strcontains(lower(rule.name), "karpenter karpenter") if contains(["operator_nodeclaim_status_condition_current_status_seconds", "karpenter_pods_unbound_time_seconds", "karpenter_cloudprovider_errors_total", "karpenter_nodepools_usage", "up"], try(rule.annotations.metric, ""))])
    error_message = "karpenter alerts must be grouped as `Karpenter` and named `Karpenter: <issue>` without repeating the namespace"
  }
}

run "slow_capacity_alerts_and_panel_are_on_by_default" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  assert {
    condition = alltrue([
      length([for rule in output.widget_alert_rules : rule if rule.expr == "count(karpenter_pods_provisioning_scheduling_undecided_time_seconds{namespace=\"karpenter\"} > 180)" && rule.pending_period == "1m" && rule.name == "Karpenter: pods wait for a scheduling decision for more than 3 minutes"]) == 1,
      length([for rule in output.widget_alert_rules : rule if rule.expr == "count(karpenter_pods_provisioning_unbound_time_seconds{namespace=\"karpenter\"} > 300)" && rule.pending_period == "1m" && rule.name == "Karpenter: node launch for pending pods takes more than 5 minutes"]) == 1,
    ])
    error_message = "scheduling decision(3m) and node launch(5m) wait alerts must be on by default with 1m pending period"
  }

  assert {
    condition     = length([for panel in output.widget_result : panel if try(panel.title, "") == "Longest pod wait for capacity" && length(panel.targets) == 3]) == 1
    error_message = "pod wait panel must show decision, node launch and since-creation waits"
  }
}

run "metrics_scrape_absent_detection_is_opt_in" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    rows = [{ type = "block/karpenter", alerts = { metrics_scrape = { alert_if_absent = true } } }]
  }

  assert {
    condition = alltrue([
      length([for rule in output.widget_alert_rules : rule if rule.expr == "(min(up{namespace=\"karpenter\",job=\"karpenter\"}) == bool 0) or absent(up{namespace=\"karpenter\",job=\"karpenter\"})"]) == 1,
      alltrue([for rule in output.widget_alert_rules : rule.labels.namespace == "karpenter"]),
    ])
    error_message = "alert_if_absent must add absent() to the scrape alert, karpenter rules must carry the namespace label"
  }
}

run "slow_capacity_alerts_are_customizable" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    rows = [{ type = "block/karpenter", alerts = { scheduling_undecided = { enabled = false }, node_launch_slow = { threshold_minutes = 3, pending_period = "2m" } } }]
  }

  assert {
    condition = alltrue([
      length([for rule in output.widget_alert_rules : rule if strcontains(rule.expr, "scheduling_undecided")]) == 0,
      length([for rule in output.widget_alert_rules : rule if rule.expr == "count(karpenter_pods_provisioning_unbound_time_seconds{namespace=\"karpenter\"} > 180)" && rule.pending_period == "2m"]) == 1,
    ])
    error_message = "slow capacity alerts must follow enabled, threshold and pending period overrides"
  }
}

run "service_restarts_pending_period_is_applied_when_set" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    rows = [{ type = "block/service", name = "app", namespace = "prod", alerts = { restarts = { pending_period = "2m" } } }]
  }

  assert {
    condition     = length([for rule in output.widget_alert_rules : rule if strcontains(rule.name, "has too many restarts") && rule.pending_period == "2m"]) == 1
    error_message = "restarts alert must use pending_period when it is set"
  }
}

run "alert_rules_have_stable_unique_uid_keys" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    rows = [
      { type = "block/service", name = "controller", workload_name = "karpenter", namespace = "karpenter", alerts = { defaults = { stable_uids = true } } },
      { type = "block/karpenter", namespace = "karpenter" },
    ]
  }

  assert {
    condition = alltrue([
      alltrue([for rule in output.widget_alert_rules : try(rule.uid_key, null) != null]),
      length(distinct([for rule in output.widget_alert_rules : rule.uid_key])) == length(output.widget_alert_rules),
      contains([for rule in output.widget_alert_rules : rule.uid_key], "karpenter/karpenter//node_drift_stuck"),
      contains([for rule in output.widget_alert_rules : rule.uid_key], "service/karpenter/controller/replicas_no"),
    ])
    error_message = "karpenter rules and opted-in service rules must have unique stable uid keys"
  }
}

run "service_rules_keep_grafana_uids_without_opt_in" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    rows = [{ type = "block/service", name = "app", namespace = "prod" }]
  }

  assert {
    condition     = alltrue([for rule in output.widget_alert_rules : try(rule.uid_key, null) == null])
    error_message = "service rules must not change uids for existing users unless stable_uids is enabled"
  }
}

run "rules_module_uid_does_not_depend_on_position" {
  command = plan

  module {
    source = "../../modules/alerts/modules/rules"
  }

  variables {
    folder_name = "dashboards"
    alert_rules = [
      { name = "first", group = "g", datasource = "prometheus", expr = "up", equation = "gt", threshold = 0, uid_key = "k1" },
      { name = "second", group = "g", datasource = "prometheus", expr = "up", equation = "gt", threshold = 0, uid_key = "k2" },
      { name = "third", group = "g", datasource = "prometheus", expr = "up", equation = "gt", threshold = 0 },
    ]
  }

  assert {
    condition = alltrue([
      grafana_rule_group.this["g"].rule[0].uid == "r${substr(sha1("dashboards/g/k1"), 0, 30)}",
      grafana_rule_group.this["g"].rule[1].uid == "r${substr(sha1("dashboards/g/k2"), 0, 30)}",
      length(grafana_rule_group.this["g"].rule[0].uid) <= 40,
    ])
    error_message = "rule uid must be derived from folder/group/uid_key only, not from rule position"
  }
}

run "karpenter_defaults_are_cloud_provider_neutral" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  assert {
    condition = alltrue([
      length([for panel in output.widget_result : panel if try(panel.title, "") == "Interruption messages received / handled"]) == 0,
      length([for panel in output.widget_result : panel if try(panel.title, "") == "Cloud provider errors"]) == 1,
      length([for rule in output.widget_alert_rules : rule if strcontains(try(rule.expr, ""), "karpenter_interruption_")]) == 0,
    ])
    error_message = "interruption queue widgets/alerts exist only with some cloud providers so they must be opt-in, cloud provider errors are generic and on by default"
  }
}

run "karpenter_alerts_and_widgets_are_customizable" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    rows = [
      {
        type      = "block/karpenter"
        namespace = "karpenter"
        columns   = 4
        widgets   = { interruption = true, controller = false, cloud_provider = false }
        alerts = {
          defaults                 = { labels = { priority = "P3", team = "platform" } }
          node_drift_stuck         = { threshold_hours = 48 }
          pods_pending             = { enabled = false }
          disruption_rate          = { enabled = true, threshold = 5, name = "Node churn is high", group = "Karpenter churn" }
          interruption_not_handled = { enabled = true }
        }
      },
    ]
  }

  assert {
    condition = alltrue([
      length([for rule in output.widget_alert_rules : rule if strcontains(rule.name, "Karpenter: node is stuck in drifted state for more than 48 hours") && rule.threshold == 48]) == 1,
      length([for rule in output.widget_alert_rules : rule if strcontains(rule.name, "pods are pending")]) == 0,
      length([for rule in output.widget_alert_rules : rule if rule.name == "Node churn is high" && rule.group == "Karpenter churn" && rule.threshold == 5]) == 1,
      length([for rule in output.widget_alert_rules : rule if strcontains(rule.name, "Karpenter: interruption messages are not handled") && rule.labels.priority == "P1"]) == 1,
      alltrue([for rule in output.widget_alert_rules : rule.labels.priority == "P3" && rule.labels.team == "platform" if strcontains(try(rule.group, ""), "Karpenter") && !strcontains(rule.name, "interruption")]),
    ])
    error_message = "karpenter alerts must follow threshold, enabled and labels overrides"
  }

  assert {
    condition = alltrue([
      length([for panel in output.widget_result : panel if try(panel.title, "") == "Interruption messages received / handled"]) == 1,
      length([for panel in output.widget_result : panel if try(panel.title, "") == "Cloud provider errors"]) == 0,
      length([for panel in output.widget_result : panel if try(panel.title, "") == "Controller reconcile errors"]) == 0,
      length([for panel in output.widget_result : panel if try(panel.title, "") == "Time in drifted state per node"]) == 1,
      alltrue([for panel in output.widget_result : panel.gridPos.w == 6 if strcontains(jsonencode(try(panel.targets, [])), "karpenter_")]),
    ])
    error_message = "karpenter widget groups must be switchable"
  }
}

run "karpenter_without_namespace_filter" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    rows = [{ type = "block/karpenter", namespace = "", extra_filters = "cluster=\"dev\"" }]
  }

  assert {
    condition = alltrue([
      contains([for rule in output.widget_alert_rules : rule.expr], "max by (name, karpenter_sh_nodepool) (operator_nodeclaim_status_condition_current_status_seconds{cluster=\"dev\",type=\"Drifted\",status=\"True\"}) / 3600"),
      alltrue([for rule in output.widget_alert_rules : rule.group == "Karpenter"]),
    ])
    error_message = "empty namespace must drop the namespace matcher so other scrape label layouts can be selected with extra_filters"
  }
}

run "karpenter_alerts_can_be_disabled" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    rows = [{ type = "block/karpenter", alerts = { enabled = false } }]
  }

  assert {
    condition     = length(output.widget_alert_rules) == 0
    error_message = "alerts.enabled = false must remove all karpenter alerts"
  }
}
