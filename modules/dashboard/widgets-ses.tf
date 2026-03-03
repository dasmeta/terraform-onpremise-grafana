# AWS SES widgets (block/aws-ses; types aws-ses/*); modules under widgets/aws/ses
module "ses_sending_quota_widget" {
  source = "./modules/widgets/aws/ses/sending-quota"

  for_each = { for index, item in try(local.widget_config["aws-ses/sending-quota"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
  min            = try(each.value.min, null)
  max            = try(each.value.max, null)
}

module "ses_send_delivery_widget" {
  source = "./modules/widgets/aws/ses/send-delivery"

  for_each = { for index, item in try(local.widget_config["aws-ses/send-delivery"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, "3600")
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "ses_bounce_rate_widget" {
  source = "./modules/widgets/aws/ses/bounce-rate"

  for_each = { for index, item in try(local.widget_config["aws-ses/bounce-rate"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "ses_complaint_rate_widget" {
  source = "./modules/widgets/aws/ses/complaint-rate"

  for_each = { for index, item in try(local.widget_config["aws-ses/complaint-rate"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "ses_bounces_timeseries_widget" {
  source = "./modules/widgets/aws/ses/bounces-timeseries"

  for_each = { for index, item in try(local.widget_config["aws-ses/bounces-timeseries"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "ses_sending_rate_widget" {
  source = "./modules/widgets/aws/ses/sending-rate"

  for_each = { for index, item in try(local.widget_config["aws-ses/sending-rate"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, "60")
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "ses_bounce_reject_widget" {
  source = "./modules/widgets/aws/ses/bounce-reject"

  for_each = { for index, item in try(local.widget_config["aws-ses/bounce-reject"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, "3600")
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}
