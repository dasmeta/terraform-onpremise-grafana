locals {
  groups = toset(distinct([for rule in var.alert_rules : coalesce(rule.group, var.group)]))
  alerts = { for member in local.groups : member => [for rule in var.alert_rules : merge(rule, {
    expr : coalesce(rule.expr, "${rule.metric_function}(${rule.metric_name}${rule.filters != null ? format("{%s}", replace(join(", ", [for k, v in rule.filters : "${k}=\"${v}\""]), "\"", "\\\"")) : ""}${rule.metric_interval})")
  }) if coalesce(rule.group, var.group) == member] }
  comparison_operators = {
    gte = { operator = ">=", definition = "greater than or equal to" },
    gt  = { operator = ">", definition = "greater than" },
    lt  = { operator = "<", definition = "less than" },
    lte = { operator = "<=", definition = "less than or equal to" },
    e   = { operator = "=", definition = "equal to" }
  }
}

resource "grafana_folder" "this" {
  count = (var.folder_name != null) && var.create_folder ? 0 : 1

  title = var.folder_name
}

data "grafana_folder" "this" {
  count = (var.folder_name != null) && !var.create_folder ? 0 : 1

  title = var.folder_name
}

resource "grafana_rule_group" "this" {
  for_each = local.alerts

  name               = each.key
  disable_provenance = var.disable_provenance
  folder_uid         = try(grafana_folder.this[0].uid, data.grafana_folder.this[0].uid)
  interval_seconds   = var.alert_interval_seconds
  dynamic "rule" {
    for_each = each.value
    content {
      name           = rule.value["name"]
      for            = lookup(rule.value, "pending_period", "0")
      condition      = "C"
      no_data_state  = lookup(rule.value, "no_data_state", "NoData")
      exec_err_state = lookup(rule.value, "exec_err_state", "Error")
      annotations = merge({
        "Managed By" = "Terraform"
        "summary"    = coalesce(rule.value.summary, "${rule.value.name} alert, the evaluated value($B) is ${rule.value.condition != null ? rule.value.condition : "${local.comparison_operators[rule.value.equation].definition} ${rule.value.threshold}"}")
        "threshold"  = try(rule.value.threshold, "")
        },
        # Merge predefined annotations (only non-empty values)
        { for k, v in var.annotations : k => v if length(v) > 0 },
        # Override with rule-specific annotations
        lookup(rule.value, "annotations", {})
      )
      labels = merge(
        # Merge predefined labels (only non-empty values)
        { for k, v in var.labels : k => v if length(v) > 0 },
        # Override with rule-specific labels
        lookup(rule.value, "labels", {})
      )
      is_paused = false
      data {
        ref_id     = "A"
        query_type = ""
        relative_time_range {
          from = 600
          to   = 0
        }
        datasource_uid = rule.value.datasource
        model          = <<EOT
{
    "editorMode": "code",
    "expr": "${rule.value.expr}",
    "hide": false,
    "legendFormat": "__auto",
    "range": true,
    "refId": "A"
}
EOT
      }
      data {
        ref_id     = "B"
        query_type = ""
        relative_time_range {
          from = 600
          to   = 0
        }
        datasource_uid = "__expr__"
        model          = <<EOT
{
    "conditions": [
        {
        "evaluator": {
            "params": [
            0,
            0
            ],
            "type": "gt"
        },
        "operator": {
            "type": "and"
        },
        "query": {
            "params": []
        },
        "reducer": {
            "params": [],
            "type": "last"
        },
        "type": "query"
        }
    ],
    "datasource": {
        "name": "Expression",
        "type": "__expr__",
        "uid": "__expr__"
    },
    "expression": "A",
    "intervalMs": 1000,
    "maxDataPoints": 43200,
    "reducer": "${rule.value.function}",
    "refId": "B",
    "type": "reduce",
    "settings": {
        "mode": "${rule.value.settings_mode}",
        "replaceWithValue": ${rule.value.settings_replaceWith}
    }
}
EOT
      }
      data {
        ref_id     = "C"
        query_type = ""
        relative_time_range {
          from = 600
          to   = 0
        }
        datasource_uid = "__expr__"
        model          = <<EOT
{
    "conditions": [
        {
        "evaluator": {
            "params": [
            0,
            0
            ],
            "type": "gt"
        },
        "operator": {
            "type": "and"
        },
        "query": {
            "params": []
        },
        "reducer": {
            "params": [],
            "type": "last"
        },
        "type": "query"
        }
    ],
    "datasource": {
        "name": "Expression",
        "type": "__expr__",
        "uid": "__expr__"
    },
    "expression": "${rule.value.condition != null ? rule.value.condition : "$B ${local.comparison_operators[rule.value.equation].operator} ${rule.value.threshold}"}",
    "hide": false,
    "intervalMs": 1000,
    "maxDataPoints": 43200,
    "refId": "C",
    "type": "math"
}
EOT
      }
    }
  }
}
