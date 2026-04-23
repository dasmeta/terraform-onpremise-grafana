output "result" {
  description = "SES block rows (widget configs); types use aws-ses/* prefix with hyphens"
  value = [
    [
      { type = "text/title-with-collapse", text = var.block_name }
    ],
    [
      { type = "aws-ses/sending-quota", width = 12, height = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period, min = var.min, max = var.max },
      { type = "aws-ses/send-delivery", width = 12, height = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period }
    ],
    [
      { type = "aws-ses/bounce-rate", width = 6, height = 7, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type = "aws-ses/complaint-rate", width = 6, height = 7, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type = "aws-ses/bounces-timeseries", width = 6, height = 7, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type = "aws-ses/sending-rate", width = 6, height = 7, region = var.region, datasource_uid = var.datasource_uid, period = var.period }
    ],
    [
      { type = "aws-ses/bounce-reject", width = 24, height = 7, region = var.region, datasource_uid = var.datasource_uid, period = var.period }
    ]
  ]
}
