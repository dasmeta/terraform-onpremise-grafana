# SES widgets

module "ses_sending_quota_widget" {
  source = "./modules/widgets/ses/sending_quota"

  for_each = { for index, item in try(local.widget_config["ses/sending_quota"], []) : index => item }

  coordinates      = each.value.coordinates
  region           = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period           = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid   = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
  standard_options = try(each.value.standard_options, { max = 100000 })
}

module "ses_send_delivery_widget" {
  source = "./modules/widgets/ses/send_delivery"

  for_each = { for index, item in try(local.widget_config["ses/send_delivery"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, "3600")
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "ses_bounce_rate_widget" {
  source = "./modules/widgets/ses/bounce_rate"

  for_each = { for index, item in try(local.widget_config["ses/bounce_rate"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "ses_complaint_rate_widget" {
  source = "./modules/widgets/ses/complaint_rate"

  for_each = { for index, item in try(local.widget_config["ses/complaint_rate"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "ses_bounces_timeseries_widget" {
  source = "./modules/widgets/ses/bounces_timeseries"

  for_each = { for index, item in try(local.widget_config["ses/bounces_timeseries"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "ses_sending_rate_widget" {
  source = "./modules/widgets/ses/sending_rate"

  for_each = { for index, item in try(local.widget_config["ses/sending_rate"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, "60")
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "ses_bounce_reject_widget" {
  source = "./modules/widgets/ses/bounce_reject"

  for_each = { for index, item in try(local.widget_config["ses/bounce_reject"], []) : index => item }

  coordinates    = each.value.coordinates
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, "3600")
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}
