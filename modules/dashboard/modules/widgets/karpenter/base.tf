locals {
  # `m` is the plain matcher list, `c` is the same with a trailing comma to prepend to panel specific matchers
  m = join(",", compact([var.namespace != "" ? "namespace=\"${var.namespace}\"" : "", var.extra_filters]))
  c = local.m == "" ? "" : "${local.m},"
  p = var.period

  panels = {
    "nodes" = {
      title       = "Nodes by nodepool / capacity type"
      description = "Number of nodes karpenter manages, per nodepool and capacity type(spot/on-demand)"
      unit        = ""
      metrics = [
        { label = "{{nodepool}} {{capacity_type}}", expression = "count by (nodepool, capacity_type) (karpenter_nodes_allocatable{${local.c}resource_type=\"cpu\",nodepool!=\"\"})" },
        { label = "total", expression = "count(karpenter_nodes_allocatable{${local.c}resource_type=\"cpu\",nodepool!=\"\"}) or vector(0)" },
      ]
    }
    "drifted-nodes" = {
      title       = "Drifted nodes waiting for replacement"
      description = "Nodes karpenter marked as drifted (node image, node class or nodepool spec changed). They get replaced within disruption budgets/windows, if the count stays above zero check do-not-disrupt annotations, PodDisruptionBudgets and nodepool disruption budgets"
      unit        = ""
      metrics = [
        { label = "{{karpenter_sh_nodepool}}", expression = "sum by (karpenter_sh_nodepool) (operator_nodeclaim_status_condition_count{${local.c}type=\"Drifted\",status=\"True\"})" },
        { label = "total", expression = "sum(operator_nodeclaim_status_condition_count{${local.c}type=\"Drifted\",status=\"True\"}) or vector(0)" },
      ]
    }
    "drift-duration" = {
      title       = "Time in drifted state per node"
      description = "How long each node is in drifted state, a node staying drifted for long (more than a day) is stuck and will not get replaced without action"
      unit        = "s"
      metrics = [
        { label = "{{name}} ({{karpenter_sh_nodepool}})", expression = "max by (name, karpenter_sh_nodepool) (operator_nodeclaim_status_condition_current_status_seconds{${local.c}type=\"Drifted\",status=\"True\"})" },
        { label = "longest", expression = "max(operator_nodeclaim_status_condition_current_status_seconds{${local.c}type=\"Drifted\",status=\"True\"}) or vector(0)" },
      ]
    }
    "nodes-created-terminated" = {
      title       = "Nodes created / terminated"
      description = "Nodes karpenter created and terminated per nodepool, each point is the count within the rate interval before it"
      unit        = ""
      metrics = [
        { label = "created {{nodepool}}", expression = "sum by (nodepool) (increase(karpenter_nodes_created_total{${local.m}}[${local.p}]))" },
        { label = "terminated {{nodepool}}", expression = "sum by (nodepool) (increase(karpenter_nodes_terminated_total{${local.m}}[${local.p}]))" },
        { label = "created total", expression = "sum(increase(karpenter_nodes_created_total{${local.m}}[${local.p}])) or vector(0)" },
        { label = "terminated total", expression = "sum(increase(karpenter_nodes_terminated_total{${local.m}}[${local.p}])) or vector(0)" },
      ]
    }
    "nodes-not-initialized" = {
      title       = "Nodes not initialized yet"
      description = "How long launched nodes are waiting to become initialized(ready to take pods), long waits point to node bootstrap, CNI or startup taint issues"
      unit        = "s"
      metrics = [
        { label = "{{name}} ({{karpenter_sh_nodepool}})", expression = "max by (name, karpenter_sh_nodepool) (operator_nodeclaim_status_condition_current_status_seconds{${local.c}type=\"Initialized\",status!=\"True\"})" },
        { label = "longest", expression = "max(operator_nodeclaim_status_condition_current_status_seconds{${local.c}type=\"Initialized\",status!=\"True\"}) or vector(0)" },
      ]
    }
    "nodes-disrupted" = {
      title       = "Nodes disrupted by reason"
      description = "Nodes karpenter removed per reason(drifted, underutilized, empty, expired, and spot_interrupted which is not voluntary) and nodepool, each point is the count within the rate interval before it"
      unit        = ""
      metrics = [
        { label = "{{reason}} {{nodepool}} {{capacity_type}}", expression = "sum by (reason, nodepool, capacity_type) (increase(karpenter_nodeclaims_disrupted_total{${local.m}}[${local.p}]))" },
        { label = "total", expression = "sum(increase(karpenter_nodeclaims_disrupted_total{${local.m}}[${local.p}])) or vector(0)" },
      ]
    }
    "disruption-decisions" = {
      title       = "Disruption decisions"
      description = "Voluntary disruption decisions(delete/replace) karpenter took per reason, each point is the count within the rate interval before it"
      unit        = ""
      metrics = [
        { label = "{{decision}} {{reason}}", expression = "sum by (decision, reason) (increase(karpenter_voluntary_disruption_decisions_total{${local.m}}[${local.p}]))" },
        { label = "total", expression = "sum(increase(karpenter_voluntary_disruption_decisions_total{${local.m}}[${local.p}])) or vector(0)" },
      ]
    }
    "interruptions" = {
      title       = "Interruption messages received / handled"
      description = "Interruption messages(spot reclaim, rebalance, scheduled maintenance, instance state change) karpenter got from its interruption queue, handled messages are deleted from the queue. Only karpenter cloud providers with an interruption queue (for example AWS SQS) expose these metrics"
      unit        = ""
      metrics = [
        { label = "received {{message_type}}", expression = "sum by (message_type) (increase(karpenter_interruption_received_messages_total{${local.m}}[${local.p}]))" },
        { label = "received total", expression = "sum(increase(karpenter_interruption_received_messages_total{${local.m}}[${local.p}])) or vector(0)" },
        { label = "handled", expression = "sum(increase(karpenter_interruption_deleted_messages_total{${local.m}}[${local.p}])) or vector(0)" },
      ]
    }
    "cloudprovider-errors" = {
      title       = "Cloud provider errors"
      description = "Errors of karpenter calls to the cloud provider per method(Create means node launch) and error type. NodeClaimNotFoundError on Get/Delete is normal right after a node is terminated, InsufficientCapacityError is usual for spot capacity and karpenter retries with other instance types; Create errors of other types need attention"
      unit        = ""
      metrics = [
        { label = "{{method}} {{error}}", expression = "sum by (method, error) (increase(karpenter_cloudprovider_errors_total{${local.m}}[${local.p}]))" },
        { label = "total", expression = "sum(increase(karpenter_cloudprovider_errors_total{${local.m}}[${local.p}])) or vector(0)" },
      ]
    }
    "nodepool-usage" = {
      title       = "Nodepool usage of limits"
      description = "Percent of each nodepool limit in use, at 100% karpenter stops launching nodes for the nodepool, shows data only for nodepools with limits"
      unit        = "percent"
      no_value    = "No nodepool limits set"
      metrics = [
        { label = "{{nodepool}} {{resource_type}}", expression = "100 * max by (nodepool, resource_type) (karpenter_nodepools_usage{${local.m}}) / max by (nodepool, resource_type) (karpenter_nodepools_limit{${local.m}})" },
      ]
    }
    "pending-pods" = {
      title       = "Pods waiting for a node"
      description = "Pending pods not scheduled to any node for more than 2 minutes, karpenter should launch capacity for them; they stay pending when no nodepool fits them, nodepool limits are reached or launches fail"
      unit        = ""
      metrics = [
        { label = "pods pending > 2m", expression = "count(karpenter_pods_unbound_time_seconds{${local.m}} > 120) or vector(0)" },
      ]
    }
    "pod-wait" = {
      title       = "Longest pod wait for capacity"
      description = "Longest wait of a pending pod per phase: for a karpenter scheduling decision (should be seconds), for the node karpenter launched (usually 1-2 minutes), and since pod creation. The first two timers are kept in controller memory and restart on controller restart"
      unit        = "s"
      metrics = [
        { label = "waiting for decision", expression = "max(karpenter_pods_provisioning_scheduling_undecided_time_seconds{${local.m}}) or vector(0)" },
        { label = "waiting for launched node", expression = "max(karpenter_pods_provisioning_unbound_time_seconds{${local.m}}) or vector(0)" },
        { label = "since pod creation", expression = "max(karpenter_pods_unbound_time_seconds{${local.m}}) or vector(0)" },
      ]
    }
    "reconcile-errors" = {
      title       = "Controller reconcile errors"
      description = "Errors of karpenter internal controllers, a steady rate points to misconfiguration(node class, cloud permissions, nodepool requirements)"
      unit        = ""
      metrics = [
        { label = "{{controller}}", expression = "sum by (controller) (rate(controller_runtime_reconcile_errors_total{${local.m}}[${local.p}])) > 0" },
        { label = "total", expression = "sum(rate(controller_runtime_reconcile_errors_total{${local.m}}[${local.p}])) or vector(0)" },
      ]
    }
  }

  panel = local.panels[var.panel]
}

module "base" {
  source = "../base"

  name        = local.panel.title
  description = local.panel.description
  unit        = local.panel.unit
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period
  no_value    = try(local.panel.no_value, null)
  metrics     = local.panel.metrics
}
