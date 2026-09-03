locals {
  selector_owned_values = {
    fullnameOverride = var.fullname_override
    service = {
      port = 8080
    }
    prometheus = {
      monitor = {
        enabled = var.prometheus_monitor_enabled
        additionalLabels = {
          release = var.prometheus_release_name
        }
        selectorOverride = {
          "app.kubernetes.io/name"     = "kube-state-metrics"
          "app.kubernetes.io/instance" = var.release_name
        }
        http = {
          honorLabels = true
        }
      }
    }
  }

  service_target = format(
    "%s.%s.svc.cluster.local:8080",
    var.fullname_override,
    var.namespace
  )
}
