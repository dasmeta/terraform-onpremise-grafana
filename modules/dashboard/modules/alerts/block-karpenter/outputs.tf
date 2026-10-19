locals {
  # `m` is the plain matcher list, `c` is the same with a trailing comma to prepend to alert specific matchers
  m = join(",", compact([var.namespace != "" ? "namespace=\"${var.namespace}\"" : "", var.extra_filters]))
  c = local.m == "" ? "" : "${local.m},"

  prefix = var.defaults.name_prefix
  group  = coalesce(var.defaults.group, local.prefix)

  enabled = {
    node_drift_stuck         = coalesce(var.alerts.node_drift_stuck.enabled, var.defaults.enabled)
    node_not_initialized     = coalesce(var.alerts.node_not_initialized.enabled, var.defaults.enabled)
    pods_pending             = coalesce(var.alerts.pods_pending.enabled, var.defaults.enabled)
    scheduling_undecided     = coalesce(var.alerts.scheduling_undecided.enabled, var.defaults.enabled)
    node_launch_slow         = coalesce(var.alerts.node_launch_slow.enabled, var.defaults.enabled)
    launch_errors            = coalesce(var.alerts.launch_errors.enabled, var.defaults.enabled)
    interruption_not_handled = coalesce(var.alerts.interruption_not_handled.enabled, false)
    nodepool_limit           = coalesce(var.alerts.nodepool_limit.enabled, var.defaults.enabled)
    metrics_scrape           = coalesce(var.alerts.metrics_scrape.enabled, var.defaults.enabled)
    disruption_rate          = coalesce(var.alerts.disruption_rate.enabled, false)
  }

  ignored_errors = join("|", var.alerts.launch_errors.ignore_errors)

  expr = {
    node_drift_stuck         = "max by (name, karpenter_sh_nodepool) (operator_nodeclaim_status_condition_current_status_seconds{${local.c}type=\"Drifted\",status=\"True\"}) / 3600"
    node_not_initialized     = "max by (name, karpenter_sh_nodepool) (operator_nodeclaim_status_condition_current_status_seconds{${local.c}type=\"Initialized\",status!=\"True\"}) / 60"
    pods_pending             = "count(karpenter_pods_unbound_time_seconds{${local.m}} > ${var.alerts.pods_pending.threshold_minutes * 60})"
    scheduling_undecided     = "count(karpenter_pods_provisioning_scheduling_undecided_time_seconds{${local.m}} > ${var.alerts.scheduling_undecided.threshold_minutes * 60})"
    node_launch_slow         = "count(karpenter_pods_provisioning_unbound_time_seconds{${local.m}} > ${var.alerts.node_launch_slow.threshold_minutes * 60})"
    launch_errors            = "sum by (error) (increase(karpenter_cloudprovider_errors_total{${local.c}method=\"Create\"${local.ignored_errors != "" ? ",error!~\"${local.ignored_errors}\"" : ""}}[${var.alerts.launch_errors.interval}]))"
    interruption_not_handled = "(sum(increase(karpenter_interruption_received_messages_total{${local.m}}[${var.alerts.interruption_not_handled.interval}])) > 0) and on() ((sum(increase(karpenter_interruption_deleted_messages_total{${local.m}}[${var.alerts.interruption_not_handled.interval}])) or vector(0)) == 0)"
    nodepool_limit           = "100 * max by (nodepool, resource_type) (karpenter_nodepools_usage{${local.m}}) / max by (nodepool, resource_type) (karpenter_nodepools_limit{${local.m}})"
    metrics_scrape           = "(min(up{${local.c}job=\"${var.alerts.metrics_scrape.job}\"}) == bool 0)${var.alerts.metrics_scrape.alert_if_absent ? " or absent(up{${local.c}job=\"${var.alerts.metrics_scrape.job}\"})" : ""}"
    disruption_rate          = "sum(increase(karpenter_nodeclaims_disrupted_total{${local.m}}[${var.alerts.disruption_rate.interval}]))"
  }

  rules = {
    node_drift_stuck = {
      name      = "${local.prefix}: node is stuck in drifted state for more than ${var.alerts.node_drift_stuck.threshold_hours} hours"
      equation  = "gt"
      threshold = var.alerts.node_drift_stuck.threshold_hours
      annotations = {
        summary      = "Karpenter node {{ $labels.name }} of nodepool {{ $labels.karpenter_sh_nodepool }} is drifted for {{ $values.B.Value | humanize }} hours and is not replaced"
        description  = "Karpenter marked the node as drifted (node image, node class or nodepool spec changed) but did not replace it. Usual causes: pods with karpenter.sh/do-not-disrupt annotation, PodDisruptionBudgets that allow no eviction, nodepool disruption budgets/windows that never allow Drifted. Check with: kubectl get nodeclaim {{ $labels.name }} -o yaml; kubectl describe node <node>"
        component    = "karpenter"
        metric       = "operator_nodeclaim_status_condition_current_status_seconds"
        issue_phrase = "node stuck in drift"
        impact       = "Node keeps running outdated image/configuration"
      }
    }
    node_not_initialized = {
      name      = "${local.prefix}: node is not initialized for more than ${var.alerts.node_not_initialized.threshold_minutes} minutes"
      equation  = "gt"
      threshold = var.alerts.node_not_initialized.threshold_minutes
      annotations = {
        summary      = "Karpenter node {{ $labels.name }} of nodepool {{ $labels.karpenter_sh_nodepool }} is not initialized for {{ $values.B.Value | humanize }} minutes"
        description  = "The node was launched but did not become ready for pods. Usual causes: node bootstrap failure, CNI not ready, startup taints not removed. Check with: kubectl get nodeclaim {{ $labels.name }} -o yaml"
        component    = "karpenter"
        metric       = "operator_nodeclaim_status_condition_current_status_seconds"
        issue_phrase = "node not initialized"
        impact       = "Pending pods wait for capacity"
      }
    }
    pods_pending = {
      name      = "${local.prefix}: pods are pending for more than ${var.alerts.pods_pending.threshold_minutes} minutes"
      equation  = "gt"
      threshold = 0
      annotations = {
        summary      = "{{ $values.B.Value }} pods are not scheduled to any node for more than ${var.alerts.pods_pending.threshold_minutes} minutes"
        description  = "Karpenter does not provide capacity for pending pods. Usual causes: no nodepool matches pod requirements/tolerations, nodepool limits reached, node launch errors. Check with: kubectl get pods -A --field-selector=status.phase=Pending; kubectl -n ${var.namespace} logs -l app.kubernetes.io/name=karpenter"
        component    = "karpenter"
        metric       = "karpenter_pods_unbound_time_seconds"
        issue_phrase = "pods pending"
        impact       = "Workloads can not start or scale"
      }
    }
    scheduling_undecided = {
      name      = "${local.prefix}: pods wait for a scheduling decision for more than ${var.alerts.scheduling_undecided.threshold_minutes} minutes"
      equation  = "gt"
      threshold = 0
      annotations = {
        summary      = "{{ $values.B.Value }} pending pods have no karpenter scheduling decision for more than ${var.alerts.scheduling_undecided.threshold_minutes} minutes"
        description  = "Karpenter sees the pending pods but does not decide where to place them, so no node launch starts. Usual causes: controller overloaded or CPU throttled, API server throttling, very large pending pod batch. The timer is kept in controller memory and restarts on controller restart. Check with: kubectl -n ${var.namespace} logs -l app.kubernetes.io/name=karpenter; kubectl -n ${var.namespace} top pods"
        component    = "karpenter"
        metric       = "karpenter_pods_provisioning_scheduling_undecided_time_seconds"
        issue_phrase = "scheduling decision delayed"
        impact       = "Workloads can not start or scale"
      }
    }
    node_launch_slow = {
      name      = "${local.prefix}: node launch for pending pods takes more than ${var.alerts.node_launch_slow.threshold_minutes} minutes"
      equation  = "gt"
      threshold = 0
      annotations = {
        summary      = "{{ $values.B.Value }} pods wait for their karpenter node for more than ${var.alerts.node_launch_slow.threshold_minutes} minutes"
        description  = "Karpenter decided to launch capacity for the pods but they are still not bound to a node. Usual causes: slow or failing instance launch (capacity errors), node bootstrap/join issues, CNI not ready, startup taints not removed. The timer is kept in controller memory and restarts on controller restart. Check with: kubectl get nodeclaims; kubectl describe nodeclaim <name>; kubectl -n ${var.namespace} logs -l app.kubernetes.io/name=karpenter"
        component    = "karpenter"
        metric       = "karpenter_pods_provisioning_unbound_time_seconds"
        issue_phrase = "node launch slow"
        impact       = "Workloads wait for capacity"
      }
    }
    launch_errors = {
      name      = "${local.prefix}: node launches fail"
      equation  = "gte"
      threshold = var.alerts.launch_errors.threshold
      annotations = {
        summary      = "Karpenter got {{ $values.B.Value | humanize }} node launch errors ({{ $labels.error }}) within ${var.alerts.launch_errors.interval}"
        description  = "Karpenter cloud provider Create calls fail. NodeClassNotReadyError means the cloud provider node class (for example EC2NodeClass on AWS) is not ready(image, network, permissions), empty error type means unclassified cloud provider errors. Check with: kubectl -n ${var.namespace} logs -l app.kubernetes.io/name=karpenter; kubectl get nodeclaims"
        component    = "karpenter"
        metric       = "karpenter_cloudprovider_errors_total"
        issue_phrase = "node launch errors"
        impact       = "New capacity can not be provisioned"
      }
    }
    interruption_not_handled = {
      name      = "${local.prefix}: interruption messages are not handled"
      equation  = "gt"
      threshold = 0
      annotations = {
        summary      = "Karpenter received {{ $values.B.Value | humanize }} interruption messages within ${var.alerts.interruption_not_handled.interval} and handled none"
        description  = "Spot interruption/rebalance/health messages are not processed, interrupted nodes are not drained before the cloud provider reclaims them. Check controller logs and its access to the interruption queue: kubectl -n ${var.namespace} logs -l app.kubernetes.io/name=karpenter"
        component    = "karpenter"
        metric       = "karpenter_interruption_received_messages_total"
        issue_phrase = "interruptions not handled"
        impact       = "Nodes get reclaimed without draining pods"
      }
    }
    nodepool_limit = {
      name      = "${local.prefix}: nodepool uses ${var.alerts.nodepool_limit.threshold_percent}% or more of its limit"
      equation  = "gte"
      threshold = var.alerts.nodepool_limit.threshold_percent
      annotations = {
        summary      = "Karpenter nodepool {{ $labels.nodepool }} uses {{ $values.B.Value | humanize }}% of its {{ $labels.resource_type }} limit"
        description  = "At 100% karpenter stops launching nodes for the nodepool and pods stay pending. Raise the nodepool limits or check what consumes the capacity: kubectl get nodepool {{ $labels.nodepool }} -o yaml"
        component    = "karpenter"
        metric       = "karpenter_nodepools_usage"
        issue_phrase = "nodepool limit"
        impact       = "New capacity will not be provisioned when limit is reached"
      }
    }
    metrics_scrape = {
      name      = "${local.prefix}: metrics are not scraped"
      equation  = "gt"
      threshold = 0
      annotations = {
        summary      = "Karpenter metrics endpoint is down for scrape job ${var.alerts.metrics_scrape.job}"
        description  = "Prometheus can not scrape karpenter metrics, the other karpenter alerts can not detect issues meanwhile. Check karpenter pods and the ServiceMonitor/scrape config."
        component    = "karpenter"
        metric       = "up"
        issue_phrase = "metrics not scraped"
        impact       = "Karpenter issues are not detected"
      }
    }
    disruption_rate = {
      name      = "${local.prefix}: too many nodes are disrupted within ${var.alerts.disruption_rate.interval}"
      equation  = "gt"
      threshold = var.alerts.disruption_rate.threshold
      annotations = {
        summary      = "Karpenter disrupted {{ $values.B.Value | humanize }} nodes within ${var.alerts.disruption_rate.interval}"
        description  = "High node churn evicts pods often. Check disruption reasons on the karpenter dashboard and nodepool consolidation/disruption budget settings."
        component    = "karpenter"
        metric       = "karpenter_nodeclaims_disrupted_total"
        issue_phrase = "node churn"
        impact       = "Frequent pod evictions"
      }
    }
  }
}

output "alert_rules" {
  description = "Grafana-managed karpenter alert rules"
  value = [
    for key, rule in local.rules : {
      name                 = coalesce(var.alerts[key].name, rule.name)
      uid_key              = "karpenter/${var.namespace}/${var.extra_filters}/${key}" # stable rule uid, so rules keep their uid(state history, links) when alerts are added/removed
      group                = coalesce(var.alerts[key].group, local.group)
      datasource           = var.datasource
      no_data_state        = var.defaults.no_data_state
      exec_err_state       = var.defaults.exec_err_state
      expr                 = local.expr[key]
      pending_period       = coalesce(var.alerts[key].pending_period, var.defaults.pending_period)
      function             = "last"
      equation             = rule.equation
      threshold            = rule.threshold
      filters              = {}
      labels               = merge(var.namespace != "" ? { namespace = var.namespace } : {}, var.defaults.labels, var.alerts[key].labels)
      annotations          = merge(rule.annotations, var.alerts[key].annotations)
      settings_mode        = "replaceNN"
      settings_replaceWith = 0
    } if local.enabled[key]
  ]
}

output "expressions" {
  description = "The PromQL expressions of all karpenter alerts(including disabled ones), used in tests"
  value       = local.expr
}
