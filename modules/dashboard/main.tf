resource "grafana_folder" "this" {
  title = var.folder_name
}

resource "grafana_dashboard" "metrics" {
  folder = grafana_folder.this.uid
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
