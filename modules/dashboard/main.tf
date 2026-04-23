resource "grafana_folder" "this" {
  count = var.create_folder ? 1 : 0
  title = var.folder_name
}

data "grafana_folder" "this" {
  count = !var.create_folder && length(var.folder_name_uids) == 0 ? 1 : 0
  title = var.folder_name
}

resource "grafana_dashboard" "metrics" {
  folder = length(var.folder_name_uids) > 0 ? var.folder_name_uids[var.folder_name] : (var.create_folder ? grafana_folder.this[0].uid : data.grafana_folder.this[0].uid)
  config_json = jsonencode({
    uid                  = random_string.grafana_dashboard_id.result
    title                = local.dashboard_title
    style                = "dark"
    timezone             = "browser"
    editable             = true
    schemaVersion        = 35
    fiscalYearStartMonth = 0
    graphTooltip         = 0
    links                = []
    liveNow              = false
    annotations          = {}
    refresh              = "1m"
    tags                 = []
    templating = {
      list = local.grafana_templating_list_variables
    }
    time = {
      from = "now-${var.time_range_hours}h"
      to   = "now"
    }
    timepicker = {}
    weekStart  = ""
    panels     = local.widget_result
  })
}

resource "random_string" "grafana_dashboard_id" {
  length  = 16
  special = false
}
