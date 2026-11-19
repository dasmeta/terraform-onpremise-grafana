variables {
  name      = "example-web"
  namespace = "example"
  defaults = {
    enabled         = false
    workload_suffix = "-primary"
  }
}

run "hpa_inputs_are_deduplicated" {
  command = plan
  variables {
    alerts = {
      replicas_min = { enabled = true }
      replicas_max = { enabled = true }
      replicas_no  = { enabled = true }
    }
  }
  assert {
    condition = contains(
      [for rule in output.alert_rules : try(rule.expr, "")],
      "max by(namespace) (kube_horizontalpodautoscaler_spec_max_replicas{namespace='example', horizontalpodautoscaler='example-web'}) - on(namespace) group_right() (max by(namespace, deployment) (kube_deployment_status_replicas_available{deployment='example-web-primary', namespace='example'}))"
    )
    error_message = "replicas_max must deduplicate both inputs."
  }
  assert {
    condition = contains(
      [for rule in output.alert_rules : try(rule.expr, "")],
      "(max by(namespace, deployment) (kube_deployment_status_replicas_available{deployment='example-web-primary', namespace='example'})) - on(namespace) group_left max by(namespace) (kube_horizontalpodautoscaler_spec_min_replicas{namespace='example', horizontalpodautoscaler='example-web'})"
    )
    error_message = "replicas_min must deduplicate both inputs."
  }
  assert {
    condition = contains(
      [for rule in output.alert_rules : try(rule.expr, "")],
      "max by(namespace, deployment) (kube_deployment_status_replicas_available{deployment='example-web-primary', namespace='example'})"
    )
    error_message = "replicas_no must deduplicate the workload input."
  }
}

run "numeric_thresholds_use_scalar_arithmetic" {
  command = plan
  variables {
    alerts = {
      replicas_min = { enabled = true, threshold = 2 }
      replicas_max = { enabled = true, threshold = 10 }
    }
  }
  assert {
    condition = contains(
      [for rule in output.alert_rules : try(rule.expr, "")],
      "(max by(namespace, deployment) (kube_deployment_status_replicas_available{deployment='example-web-primary', namespace='example'})) - 2"
    )
    error_message = "replicas_min scalar threshold must not use vector matching."
  }
  assert {
    condition = contains(
      [for rule in output.alert_rules : try(rule.expr, "")],
      "10 - (max by(namespace, deployment) (kube_deployment_status_replicas_available{deployment='example-web-primary', namespace='example'}))"
    )
    error_message = "replicas_max scalar threshold must not use vector matching."
  }
}

run "deployment_defaults_plan" {
  command = plan
  variables { defaults = { workload_suffix = "-primary" } }
  assert {
    condition     = length(output.alert_rules) > 0
    error_message = "Default deployment alerts must plan."
  }
}

run "daemonset_plans" {
  command = plan
  variables {
    defaults = { workload_type = "daemonset" }
    alerts   = { replicas_no = { enabled = true } }
  }
  assert {
    condition = contains(
      [for rule in output.alert_rules : try(rule.expr, "")],
      "max by(namespace, daemonset) (kube_daemonset_status_number_ready{daemonset='example-web', namespace='example'})"
    )
    error_message = "Daemonset replica alerts must deduplicate source series."
  }
}

run "statefulset_plans" {
  command = plan
  variables {
    defaults = { workload_type = "statefulset" }
    alerts   = { replicas_no = { enabled = true } }
  }
  assert {
    condition = contains(
      [for rule in output.alert_rules : try(rule.expr, "")],
      "max by(namespace, statefulset) (kube_statefulset_status_replicas_available{statefulset='example-web', namespace='example'})"
    )
    error_message = "Statefulset replica alerts must deduplicate source series."
  }
}

run "cronjob_plans" {
  command = plan
  variables { defaults = { workload_type = "cronjob" } }
  assert {
    condition     = length(output.alert_rules) > 0
    error_message = "Cronjob alerts must plan without a replica metric."
  }
}

run "job_plans" {
  command = plan
  variables { defaults = { workload_type = "job" } }
  assert {
    condition     = length(output.alert_rules) > 0
    error_message = "Job alerts must plan without a replica metric."
  }
}
