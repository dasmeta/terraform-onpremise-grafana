module "base" {
  source = "../../base"

  name = "Exporter scrape health"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period
  type        = "stat"

  metrics = [
    { label = "{{job}}", color = "37872D", expression = "sum by (job) (up${local.selector})" },
  ]
}
