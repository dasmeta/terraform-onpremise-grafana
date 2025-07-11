resource "grafana_notification_policy" "this" {
  count = var.notifications != null ? 1 : 0

  contact_point      = var.notifications.contact_point
  group_by           = var.notifications.group_by
  group_interval     = var.notifications.group_interval
  repeat_interval    = var.notifications.repeat_interval
  disable_provenance = var.disable_provenance

  dynamic "policy" {
    for_each = var.notifications.policies

    content {
      contact_point = policy.value.contact_point
      continue      = policy.value.continue
      group_by      = policy.value.group_by
      mute_timings  = grafana_mute_timing.this.*.name

      dynamic "matcher" {
        for_each = policy.value.matchers

        content {
          label = matcher.value.label
          match = matcher.value.match
          value = matcher.value.value
        }
      }

      dynamic "policy" {
        for_each = try(policy.value.policies, [])

        content {
          contact_point = policy.value.contact_point
          continue      = policy.value.continue
          group_by      = policy.value.group_by
          mute_timings  = grafana_mute_timing.this.*.name

          dynamic "matcher" {
            for_each = policy.value.matchers

            content {
              label = matcher.value.label
              match = matcher.value.match
              value = matcher.value.value
            }
          }
        }
      }
    }
  }
}

resource "grafana_mute_timing" "this" {
  count = try(var.notifications.mute_timing, null) != null ? 1 : 0

  name               = "Default mute timing"
  disable_provenance = var.disable_provenance


  dynamic "intervals" {
    for_each = try(var.notifications.mute_timing.intervals, [])

    content {
      weekdays      = try(intervals.value.weekdays, null)
      days_of_month = try(intervals.value.days_of_month, null)
      months        = try(intervals.value.months, null)
      years         = try(intervals.value.years, null)
      location      = try(intervals.value.location, null)

      dynamic "times" {
        for_each = try(intervals.value.times, [])

        content {
          start = try(times.value.start, "00:00")
          end   = try(times.value.end, "24:59")
        }
      }
    }
  }
}
