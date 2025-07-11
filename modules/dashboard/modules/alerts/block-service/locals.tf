locals {
  type_specific_defaults = {
    deployment = {
      defaults = {
        replicas_count_expr = "kube_deployment_status_replicas_available{deployment='${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}', namespace='${var.namespace}'}"
      }
    }
    daemonset = {
      defaults = {
        replicas_count_expr = "kube_daemonset_status_number_ready{daemonset='${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}', namespace='${var.namespace}'}"
      }
      alerts = {
        replicas_min = { enabled = false }
        replicas_max = { enabled = false }
      }
    }
    statefulset = {
      defaults = {
        replicas_count_expr = "kube_statefulset_status_replicas_available{statefulset='${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}', namespace='${var.namespace}'}"
      }
    }
    cronjob = {
      defaults = {
        enabled       = false
        no_data_state = "OK"
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

  defaults = module.defaults_deep.merged.defaults
  alerts   = module.defaults_deep.merged.alerts
}

module "defaults_deep" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"

  maps = [
    {
      defaults = var.defaults
      alerts   = var.alerts
    },
    {
      defaults = try(local.type_specific_defaults[var.defaults.workload_type].defaults, {})
      alerts   = try(local.type_specific_defaults[var.defaults.workload_type].alerts, {})
    }
  ]
}
