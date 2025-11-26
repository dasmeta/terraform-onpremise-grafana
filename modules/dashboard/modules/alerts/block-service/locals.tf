locals {
  type_specific_defaults = {
    deployment = {
      defaults = {
        replicas_count_expr = "kube_deployment_status_replicas_available{deployment='${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}', namespace='${var.namespace}'}"
        labels = {
          priority = "P1"
          slack    = "true"
        }
      }
    }
    daemonset = {
      defaults = {
        replicas_count_expr = "kube_daemonset_status_number_ready{daemonset='${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}', namespace='${var.namespace}'}"
        labels = {
          priority = "P1"
          slack    = "true"
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
          priority = "P1"
          slack    = "true"
        }
      }
    }
    cronjob = {
      defaults = {
        enabled       = false
        no_data_state = "OK"
        labels = {
          priority = "P2"
          slack    = "true"
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
          priority = "P2"
          slack    = "true"
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
}
