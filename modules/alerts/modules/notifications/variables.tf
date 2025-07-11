variable "disable_provenance" {
  type        = bool
  default     = true
  description = "Allow modifying the notification policy from other sources than Terraform or the Grafana API."
}

variable "notifications" {
  type = object({
    contact_point   = optional(string, "Slack")       # The default contact point to route all unmatched notifications to
    group_by        = optional(list(string), ["..."]) # A list of alert labels to group alerts into notifications by
    group_interval  = optional(string, "5m")          # Minimum time interval between two notifications for the same group
    repeat_interval = optional(string, "4h")          # Minimum time interval for re-sending a notification if an alert is still firing

    mute_timing = optional(object({                  # Mute timing config, which will be applied on all policies
      name = optional(string, "Default mute timing") # the name of mute timing
      intervals = optional(list(object({             # the mute timing interval configs
        weekdays      = optional(string, null)
        days_of_month = optional(string, null)
        months        = optional(string, null)
        years         = optional(string, null)
        location      = optional(string, null)
        times = optional(object({
          start = optional(string, "00:00")
          end   = optional(string, "24:59")
        }), null)
      })), [])
    }), null)

    policies = optional(list(object({
      contact_point = optional(string, null) # The contact point to route notifications that match this rule to
      continue      = optional(bool, true)   # Whether to continue matching subsequent rules if an alert matches the current rule. Otherwise, the rule will be 'consumed' by the first policy to match it
      group_by      = optional(list(string), ["..."])

      matchers = optional(list(object({
        label = optional(string, "priority") # The name of the label to match against
        match = optional(string, "=")        # The operator to apply when matching values of the given label. Allowed operators are = for equality, != for negated equality, =~ for regex equality, and !~ for negated regex equality
        value = optional(string, "P1")       # The label value to match against
      })), [])
      policies = optional(list(object({ # sub-policies(there is also possibility to implement also ability for sub.sub.sub-policies, but for not seems existing configs are enough)
        contact_point = optional(string, null)
        continue      = optional(bool, true)
        group_by      = optional(list(string), ["..."])
        mute_timings  = optional(list(string), [])

        matchers = optional(list(object({
          label = optional(string, "priority")
          match = optional(string, "=")
          value = optional(string, "P1")
        })), [])
      })), [])
    })), [])
  })
  description = "Represents the configuration options for Grafana notification policies. This config is global for grafana and overrides existing configs."
  default     = null
}
