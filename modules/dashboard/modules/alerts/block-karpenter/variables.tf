variable "namespace" {
  nullable    = false
  type        = string
  default     = "karpenter"
  description = "The namespace where karpenter controller runs, karpenter metrics get this namespace label from the scrape target so it is used to select karpenter metrics"
}

variable "extra_filters" {
  nullable    = false
  type        = string
  default     = ""
  description = "Additional PromQL label matchers appended to every alert query, for example `job=\"karpenter\"`"
}

variable "datasource" {
  nullable    = false
  type        = string
  default     = "prometheus"
  description = "The grafana datasource uid used by alerts"
}

variable "defaults" {
  type = object({
    enabled        = optional(bool, true)                                     # whether karpenter alerts are enabled by default, single alerts can still be enabled/disabled with their own `enabled`
    labels         = optional(any, { priority = "P2", severity = "warning" }) # the labels attached to all karpenter alerts, single alerts can extend/override them
    pending_period = optional(string, "5m")                                   # how long condition should last to fire alert, if alert `pending_period` is null
    no_data_state  = optional(string, "OK")                                   # karpenter alert queries return no data when nothing is wrong(no drifted nodes, no pending pods, no karpenter in cluster), so no data is OK by default
    exec_err_state = optional(string, "Error")                                # how to handle query execution errors
    name_prefix    = optional(string, "Karpenter")                            # prefix of all alert names and the default group name, set a distinct one(for example `Karpenter prod`) when several karpenter blocks share an alerts folder
    group          = optional(string, null)                                   # grafana alert group name, if null `name_prefix` is used
  })
  default     = {}
  description = "The default values used by all karpenter alerts"
}

variable "alerts" {
  type = object({
    node_drift_stuck = optional(object({          # a node is in drifted state longer than threshold, it is not getting replaced (do-not-disrupt pods, blocking PDBs, budgets/windows that never allow drift)
      enabled         = optional(bool, null)      # whether alert is enabled, if null defaults.enabled is used
      name            = optional(string, null)    # alert name override, if null a descriptive name prefixed with defaults.name_prefix is used
      group           = optional(string, null)    # grafana alert group override, if null defaults.group is used
      threshold_hours = optional(number, 24)      # how many hours a node can stay in drifted state before alert fires
      pending_period  = optional(string, null)    # how long condition should last to fire alert, if null defaults.pending_period is used
      labels          = optional(any, {})         # alert labels, extends/overrides defaults.labels
      annotations     = optional(map(string), {}) # alert annotations
    }), {})
    node_not_initialized = optional(object({     # a launched node does not get initialized(ready for pods) for longer than threshold, points to bootstrap/CNI/startup taint issues
      enabled           = optional(bool, null)   # whether alert is enabled, if null defaults.enabled is used
      name              = optional(string, null) # alert name override, if null a descriptive name prefixed with defaults.name_prefix is used
      group             = optional(string, null) # grafana alert group override, if null defaults.group is used
      threshold_minutes = optional(number, 30)   # how many minutes a node can stay not initialized before alert fires
      pending_period    = optional(string, null) # how long condition should last to fire alert, if null defaults.pending_period is used
      labels            = optional(any, {})      # alert labels, extends/overrides defaults.labels
      annotations       = optional(map(string), {})
    }), {})
    pods_pending = optional(object({             # pods stay unscheduled for longer than threshold, karpenter is not able to provide capacity for them
      enabled           = optional(bool, null)   # whether alert is enabled, if null defaults.enabled is used
      name              = optional(string, null) # alert name override, if null a descriptive name prefixed with defaults.name_prefix is used
      group             = optional(string, null) # grafana alert group override, if null defaults.group is used
      threshold_minutes = optional(number, 15)   # how many minutes a pod can stay unscheduled before alert fires
      pending_period    = optional(string, null) # how long condition should last to fire alert, if null defaults.pending_period is used
      labels            = optional(any, {})      # alert labels, extends/overrides defaults.labels
      annotations       = optional(map(string), {})
    }), {})
    scheduling_undecided = optional(object({     # karpenter sees pending pods but makes no scheduling decision for them, the controller is stuck/overloaded/throttled before any node launch starts
      enabled           = optional(bool, null)   # whether alert is enabled, if null defaults.enabled is used
      name              = optional(string, null) # alert name override, if null a descriptive name prefixed with defaults.name_prefix is used
      group             = optional(string, null) # grafana alert group override, if null defaults.group is used
      threshold_minutes = optional(number, 3)    # how many minutes a pod can wait for karpenter scheduling decision before alert fires
      pending_period    = optional(string, "1m") # how long condition should last to fire alert
      labels            = optional(any, {})      # alert labels, extends/overrides defaults.labels
      annotations       = optional(map(string), {})
    }), {})
    node_launch_slow = optional(object({         # karpenter decided to launch capacity for pending pods but they are still not bound to a node, the node launch/join is slow
      enabled           = optional(bool, null)   # whether alert is enabled, if null defaults.enabled is used
      name              = optional(string, null) # alert name override, if null a descriptive name prefixed with defaults.name_prefix is used
      group             = optional(string, null) # grafana alert group override, if null defaults.group is used
      threshold_minutes = optional(number, 5)    # how many minutes a pod can wait for its node after karpenter decision before alert fires, usual node launch takes 1-2 minutes
      pending_period    = optional(string, "1m") # how long condition should last to fire alert
      labels            = optional(any, {})      # alert labels, extends/overrides defaults.labels
      annotations       = optional(map(string), {})
    }), {})
    launch_errors = optional(object({                                        # karpenter fails to launch nodes(cloud provider Create errors), InsufficientCapacityError is excluded by default as karpenter retries other instance types
      enabled        = optional(bool, null)                                  # whether alert is enabled, if null defaults.enabled is used
      name           = optional(string, null)                                # alert name override, if null a descriptive name prefixed with defaults.name_prefix is used
      group          = optional(string, null)                                # grafana alert group override, if null defaults.group is used
      threshold      = optional(number, 5)                                   # the count of launch errors within interval to fire alert
      interval       = optional(string, "15m")                               # the time interval to count errors in
      ignore_errors  = optional(list(string), ["InsufficientCapacityError"]) # error types(`error` label values) to not count
      pending_period = optional(string, null)                                # how long condition should last to fire alert, if null defaults.pending_period is used
      labels         = optional(any, {})                                     # alert labels, extends/overrides defaults.labels
      annotations    = optional(map(string), {})
    }), {})
    interruption_not_handled = optional(object({                                 # karpenter receives interruption messages(spot reclaim, rebalance, health events) but does not handle any of them; only providers with an interruption queue (AWS SQS) expose these metrics so it is opt-in
      enabled        = optional(bool, false)                                     # whether alert is enabled
      name           = optional(string, null)                                    # alert name override, if null a descriptive name prefixed with defaults.name_prefix is used
      group          = optional(string, null)                                    # grafana alert group override, if null defaults.group is used
      interval       = optional(string, "15m")                                   # the time interval to compare received and handled messages in
      pending_period = optional(string, null)                                    # how long condition should last to fire alert, if null defaults.pending_period is used
      labels         = optional(any, { priority = "P1", severity = "critical" }) # unhandled spot interruptions mean nodes are reclaimed without drain, so critical by default
      annotations    = optional(map(string), {})
    }), {})
    nodepool_limit = optional(object({           # a nodepool uses most of its limits, at 100% karpenter stops launching nodes for it
      enabled           = optional(bool, null)   # whether alert is enabled, if null defaults.enabled is used
      name              = optional(string, null) # alert name override, if null a descriptive name prefixed with defaults.name_prefix is used
      group             = optional(string, null) # grafana alert group override, if null defaults.group is used
      threshold_percent = optional(number, 90)   # the percent of nodepool limit usage to fire alert
      pending_period    = optional(string, null) # how long condition should last to fire alert, if null defaults.pending_period is used
      labels            = optional(any, {})      # alert labels, extends/overrides defaults.labels
      annotations       = optional(map(string), {})
    }), {})
    metrics_scrape = optional(object({                # karpenter metrics endpoint is not scraped successfully, all other karpenter alerts are blind then
      enabled         = optional(bool, null)          # whether alert is enabled, if null defaults.enabled is used
      name            = optional(string, null)        # alert name override, if null a descriptive name prefixed with defaults.name_prefix is used
      group           = optional(string, null)        # grafana alert group override, if null defaults.group is used
      alert_if_absent = optional(bool, false)         # also fire when no `up` series exists for the job at all(scrape config removed, karpenter uninstalled); off by default so clusters without karpenter stay silent
      job             = optional(string, "karpenter") # the scrape job name(`job` label of karpenter metrics), with ServiceMonitor/service based scrape it is the karpenter service name
      pending_period  = optional(string, null)        # how long condition should last to fire alert, if null defaults.pending_period is used
      labels          = optional(any, {})             # alert labels, extends/overrides defaults.labels
      annotations     = optional(map(string), {})
    }), {})
    disruption_rate = optional(object({       # too many nodes get disrupted, possible consolidation/drift churn; depends on cluster size so disabled by default
      enabled        = optional(bool, false)  # whether alert is enabled
      name           = optional(string, null) # alert name override, if null a descriptive name prefixed with defaults.name_prefix is used
      group          = optional(string, null) # grafana alert group override, if null defaults.group is used
      threshold      = optional(number, 20)   # the count of disrupted nodes within interval to fire alert
      interval       = optional(string, "1h") # the time interval to count disrupted nodes in
      pending_period = optional(string, null) # how long condition should last to fire alert, if null defaults.pending_period is used
      labels         = optional(any, {})      # alert labels, extends/overrides defaults.labels
      annotations    = optional(map(string), {})
    }), {})
  })
  default     = {}
  description = "Karpenter alerts configs, every alert can be enabled/disabled and customized separately"
}
