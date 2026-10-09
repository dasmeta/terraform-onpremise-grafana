resource "helm_release" "victoria_metrics" {
  name             = var.release_name
  repository       = "https://victoriametrics.github.io/helm-charts"
  chart            = "victoria-metrics-cluster"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  timeout          = 600
  version          = var.chart_version

  values = [jsonencode(local.cluster_effective_values)]

  lifecycle {
    precondition {
      condition     = !var.agent_enabled || var.operator_enabled
      error_message = "operator_enabled=true is required when agent_enabled=true."
    }
  }
}

resource "helm_release" "victoria_metrics_operator" {
  count = var.operator_enabled ? 1 : 0

  name             = var.operator_release_name
  repository       = "https://victoriametrics.github.io/helm-charts"
  chart            = "victoria-metrics-operator"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  timeout          = 600
  version          = var.operator_chart_version

  values = [
    jsonencode(var.operator_extra_configs),
    jsonencode(local.operator_selector_owned_values),
  ]

  depends_on = [helm_release.victoria_metrics]
}

resource "helm_release" "victoria_metrics_resources" {
  count = var.operator_enabled ? 1 : 0

  name             = "${var.operator_release_name}-resources"
  chart            = "${path.module}/charts/resources"
  namespace        = var.namespace
  create_namespace = false
  timeout          = 600

  values = [
    jsonencode({ objects = local.operator_objects }),
  ]

  depends_on = [helm_release.victoria_metrics_operator]
}
