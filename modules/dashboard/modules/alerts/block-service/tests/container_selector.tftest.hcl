variables {
  name      = "service"
  namespace = "monitoring"

  defaults = {
    container_name = "worker"
    workload_name  = "background-worker"
  }

  alerts = {
    cpu      = { enabled = true }
    memory   = { enabled = true }
    restarts = { enabled = true }
  }
}

run "resource_alerts_scope_container_metrics_to_the_workload_pods" {
  command = plan

  assert {
    condition = contains(
      [for rule in output.alert_rules : rule.expr],
      "increase(kube_pod_container_status_restarts_total{container='worker', pod=~'^background-worker(-(primary|canary))?(-[^-]+)?-[^-]+$', namespace='monitoring'}[5m])"
    )
    error_message = "Restart alerts must use the overridden container and workload pod selector."
  }

  assert {
    condition = alltrue([
      for rule in output.alert_rules :
      (
        !strcontains(rule.name, "cpu overloaded") &&
        !strcontains(rule.name, "memory overloaded")
      ) || strcontains(rule.expr, "container='worker', pod=~'^background-worker(-(primary|canary))?(-[^-]+)?-[^-]+$', namespace='monitoring'")
    ])
    error_message = "CPU and memory alerts must use the overridden container and workload pod selector."
  }
}
