variables {
  name      = "appstauber-web"
  namespace = "appstauber"

  defaults = {
    enabled         = false
    workload_suffix = "-primary"
  }

  alerts = {
    replicas_min = {
      enabled = true
    }
    replicas_max = {
      enabled = true
    }
  }
}

run "hpa_replica_alerts_deduplicate_kube_state_metrics_inputs" {
  command = plan

  assert {
    condition = contains(
      [for rule in output.alert_rules : rule.expr],
      "max by(namespace, horizontalpodautoscaler) (kube_horizontalpodautoscaler_spec_max_replicas{namespace='appstauber', horizontalpodautoscaler='appstauber-web'}) - on(namespace) group_left(deployment) (max by(namespace, deployment) (kube_deployment_status_replicas_available{deployment='appstauber-web-primary', namespace='appstauber'}))"
    )
    error_message = "replicas_max must deduplicate both HPA and deployment kube-state-metrics series before joining."
  }

  assert {
    condition = contains(
      [for rule in output.alert_rules : rule.expr],
      "(max by(namespace, deployment) (kube_deployment_status_replicas_available{deployment='appstauber-web-primary', namespace='appstauber'})) - on(namespace) group_right(deployment) max by(namespace, horizontalpodautoscaler) (kube_horizontalpodautoscaler_spec_min_replicas{namespace='appstauber', horizontalpodautoscaler='appstauber-web'})"
    )
    error_message = "replicas_min must deduplicate both deployment and HPA kube-state-metrics series before joining."
  }
}
