locals {
  type_specific_defaults = {
    deployment = {
      defaults = {
        replicas_count_expr       = "kube_deployment_status_replicas_available{deployment='${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}', namespace='${var.namespace}'}"
        unavailable_replicas_expr = "kube_deployment_status_replicas_unavailable{deployment='${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}', namespace='${var.namespace}'}"
        labels = {
          slack = "true"
        }
      }
    }
    daemonset = {
      defaults = {
        replicas_count_expr = "kube_daemonset_status_number_ready{daemonset='${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}', namespace='${var.namespace}'}"
        labels = {
          slack = "true"
        }
      }
      alerts = {
        replicas_min = { enabled = false }
        replicas_max = { enabled = false }
      }
    }
    statefulset = {
      defaults = {
        replicas_count_expr = "kube_statefulset_status_replicas_available{statefulset='${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}', namespace='${var.namespace}'}"
        labels = {
          slack = "true"
        }
      }
    }
    cronjob = {
      defaults = {
        enabled       = false
        no_data_state = "OK"
        labels = {
          slack = "true"
        }
      }
      alerts = {
        replicas_state = { enabled = true }
        job_failed     = { enabled = true }
        restarts       = { enabled = true }
        cpu            = { enabled = true }
        memory         = { enabled = true }
      }
    }
    job = {
      defaults = {
        enabled       = false
        no_data_state = "OK"
        labels = {
          slack = "true"
        }
      }
      alerts = {
        replicas_state = { enabled = true }
        job_failed     = { enabled = true }
        restarts       = { enabled = true }
        cpu            = { enabled = true }
        memory         = { enabled = true }
      }
    }
  }

  defaults = provider::deepmerge::mergo(var.defaults, try(local.type_specific_defaults[var.defaults.workload_type].defaults, {}))
  alerts   = provider::deepmerge::mergo(var.alerts, try(local.type_specific_defaults[var.defaults.workload_type].alerts, {}))

  alert_type_labels = {
    replicas_no = {
      priority = "P1"
      severity = "critical"
    }
    replicas_min = {
      priority = "P2"
      severity = "warning"
    }
    replicas_max = {
      priority = "P2"
      severity = "warning"
    }
    replicas_state = {
      priority = "P2"
      severity = "warning"
    }
    unavailable_replicas = {
      priority = "P2"
      severity = "warning"
    }
    job_failed = {
      priority = "P2"
      severity = "warning"
    }
    restarts = {
      priority = "P2"
      severity = "warning"
    }
    network_in = {
      priority = "P3"
      severity = "warning"
    }
    network_out = {
      priority = "P3"
      severity = "warning"
    }
    cpu = {
      priority = "P2"
      severity = "warning"
    }
    memory = {
      priority = "P2"
      severity = "warning"
    }
  }

  replicas_min_enabled         = coalesce(local.alerts.replicas_min.enabled, local.defaults.enabled && local.alerts.replicas_min.threshold != null, false)
  replicas_max_enabled         = coalesce(local.alerts.replicas_max.enabled, local.defaults.enabled && local.alerts.replicas_max.threshold != null, false)
  unavailable_replicas_enabled = local.defaults.workload_type == "deployment" && coalesce(local.alerts.unavailable_replicas.enabled, local.defaults.enabled, false)
  network_in_enabled           = coalesce(local.alerts.network_in.enabled, false)
  network_out_enabled          = coalesce(local.alerts.network_out.enabled, false)
}
