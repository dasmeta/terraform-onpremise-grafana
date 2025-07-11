## Usage
This Terraform module helps you manage Grafana notification policies, making it easier to configure alert notifications for different contact points and conditions.

Notification policies can be created for various contact points. Additionally, you can have nested policies.

Please refer to the `tests` folder for real examples.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 1.40.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_grafana"></a> [grafana](#provider\_grafana) | >= 1.40.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [grafana_mute_timing.this](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/mute_timing) | resource |
| [grafana_notification_policy.this](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/notification_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disable_provenance"></a> [disable\_provenance](#input\_disable\_provenance) | Allow modifying the notification policy from other sources than Terraform or the Grafana API. | `bool` | `true` | no |
| <a name="input_notifications"></a> [notifications](#input\_notifications) | Represents the configuration options for Grafana notification policies. This config is global for grafana and overrides existing configs. | <pre>object({<br/>    contact_point   = optional(string, "Slack")       # The default contact point to route all unmatched notifications to<br/>    group_by        = optional(list(string), ["..."]) # A list of alert labels to group alerts into notifications by<br/>    group_interval  = optional(string, "5m")          # Minimum time interval between two notifications for the same group<br/>    repeat_interval = optional(string, "4h")          # Minimum time interval for re-sending a notification if an alert is still firing<br/><br/>    mute_timing = optional(object({                  # Mute timing config, which will be applied on all policies<br/>      name = optional(string, "Default mute timing") # the name of mute timing<br/>      intervals = optional(list(object({             # the mute timing interval configs<br/>        weekdays      = optional(string, null)<br/>        days_of_month = optional(string, null)<br/>        months        = optional(string, null)<br/>        years         = optional(string, null)<br/>        location      = optional(string, null)<br/>        times = optional(object({<br/>          start = optional(string, "00:00")<br/>          end   = optional(string, "24:59")<br/>        }), null)<br/>      })), [])<br/>    }), null)<br/><br/>    policies = optional(list(object({<br/>      contact_point = optional(string, null) # The contact point to route notifications that match this rule to<br/>      continue      = optional(bool, true)   # Whether to continue matching subsequent rules if an alert matches the current rule. Otherwise, the rule will be 'consumed' by the first policy to match it<br/>      group_by      = optional(list(string), ["..."])<br/><br/>      matchers = optional(list(object({<br/>        label = optional(string, "priority") # The name of the label to match against<br/>        match = optional(string, "=")        # The operator to apply when matching values of the given label. Allowed operators are = for equality, != for negated equality, =~ for regex equality, and !~ for negated regex equality<br/>        value = optional(string, "P1")       # The label value to match against<br/>      })), [])<br/>      policies = optional(list(object({ # sub-policies(there is also possibility to implement also ability for sub.sub.sub-policies, but for not seems existing configs are enough)<br/>        contact_point = optional(string, null)<br/>        continue      = optional(bool, true)<br/>        group_by      = optional(list(string), ["..."])<br/>        mute_timings  = optional(list(string), [])<br/><br/>        matchers = optional(list(object({<br/>          label = optional(string, "priority")<br/>          match = optional(string, "=")<br/>          value = optional(string, "P1")<br/>        })), [])<br/>      })), [])<br/>    })), [])<br/>  })</pre> | `null` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
