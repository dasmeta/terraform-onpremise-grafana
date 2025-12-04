# ALB Ingress widgets

module "alb_ingress_connections_widget" {
  source = "./modules/widgets/alb_ingress/connections"

  for_each = { for index, item in try(local.widget_config["alb_ingress/connections"], []) : index => item }

  coordinates       = each.value.coordinates
  load_balancer_arn = try(each.value.load_balancer_arn, local.widget_default_values.cloudwatch.load_balancer_arn)
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "alb_ingress_target_response_time_widget" {
  source = "./modules/widgets/alb_ingress/target_response_time"

  for_each = { for index, item in try(local.widget_config["alb_ingress/target_response_time"], []) : index => item }

  coordinates       = each.value.coordinates
  load_balancer_arn = try(each.value.load_balancer_arn, local.widget_default_values.cloudwatch.load_balancer_arn)
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "alb_ingress_request_count_widget" {
  source = "./modules/widgets/alb_ingress/request_count"

  for_each = { for index, item in try(local.widget_config["alb_ingress/request_count"], []) : index => item }

  coordinates       = each.value.coordinates
  load_balancer_arn = try(each.value.load_balancer_arn, local.widget_default_values.cloudwatch.load_balancer_arn)
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)

}

module "alb_ingress_target_http_response_widget" {
  source = "./modules/widgets/alb_ingress/target_http_response"

  for_each = { for index, item in try(local.widget_config["alb_ingress/target_http_response"], []) : index => item }

  coordinates       = each.value.coordinates
  load_balancer_arn = try(each.value.load_balancer_arn, local.widget_default_values.cloudwatch.load_balancer_arn)
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}
