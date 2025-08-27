resource "grafana_folder" "this" {
  count = var.skip_folder_creation ? 1 : 0
  title = var.folder_name
}

data "grafana_folder" "this" {
  count = var.skip_folder_creation ? 0 : 1
  title = var.folder_name
}

resource "grafana_dashboard" "metrics" {
  folder = var.skip_folder_creation ? grafana_folder.this[0].uid : data.grafana_folder.this[0].uid
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
      from = "now-6h"
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
