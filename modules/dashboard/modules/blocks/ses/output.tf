output "result" {
  description = "SES block rows (widget configs)"
  value = [
    [
      { type = "text/title-with-collapse", text = var.block_name }
    ],
    [
      { type = "ses/sending_quota", width = 12, height = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period, standard_options = var.sending_quota_standard_options },
      { type = "ses/send_delivery", width = 12, height = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period }
    ],
    [
      { type = "ses/bounce_rate", width = 6, height = 7, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type = "ses/complaint_rate", width = 6, height = 7, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type = "ses/bounces_timeseries", width = 6, height = 7, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type = "ses/sending_rate", width = 6, height = 7, region = var.region, datasource_uid = var.datasource_uid, period = var.period }
    ],
    [
      { type = "ses/bounce_reject", width = 24, height = 7, region = var.region, datasource_uid = var.datasource_uid, period = var.period }
    ]
  ]
}
