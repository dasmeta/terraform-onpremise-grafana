module "base_grafana" {
  source = "./platforms/grafana"

  name               = var.name
  description        = var.description
  data_source        = var.data_source
  coordinates        = var.coordinates
  metrics            = var.metrics
  defaults           = var.defaults
  stat               = var.stat
  period             = var.period
  anomaly_detection  = var.anomaly_detection
  anomaly_deviation  = var.anomaly_deviation
  type               = var.type
  query              = var.query
  sources            = var.sources
  view               = var.view
  thresholds         = var.thresholds
  color_mode         = var.color_mode
  annotations        = var.annotations
  alarms             = var.alarms
  region             = var.region
  decimals           = var.decimals
  unit               = var.unit
  fillOpacity        = var.fillOpacity
  options            = var.options
  cloudwatch_targets = var.cloudwatch_targets
}
