# Ingress widgets

module "alb_ingress_connections_widget" {
  source = "./modules/widgets/alb_ingress/connections"

  for_each = { for index, item in try(local.widget_config["alb_ingress/connections"], []) : index => item }

  datasource_uid    = try(each.value.datasource_uid, null)
  coordinates       = each.value.coordinates
  period            = each.value.period
  load_balancer_arn = each.value.load_balancer_arn

  region = each.value.region
}

module "alb_ingress_target_response_time_widget" {
  source = "./modules/widgets/alb_ingress/target_response_time"

  for_each = { for index, item in try(local.widget_config["alb_ingress/target_response_time"], []) : index => item }

  datasource_uid    = try(each.value.datasource_uid, null)
  coordinates       = each.value.coordinates
  period            = each.value.period
  load_balancer_arn = each.value.load_balancer_arn

  region = each.value.region
}

module "alb_ingress_request_count_widget" {
  source = "./modules/widgets/alb_ingress/connections"

  for_each = { for index, item in try(local.widget_config["alb_ingress/request_count"], []) : index => item }

  datasource_uid    = try(each.value.datasource_uid, null)
  coordinates       = each.value.coordinates
  period            = each.value.period
  load_balancer_arn = each.value.load_balancer_arn

  region = each.value.region
}

module "alb_ingress_target_http_response_widget" {
  source = "./modules/widgets/alb_ingress/target_http_response"

  for_each = { for index, item in try(local.widget_config["alb_ingress/target_http_response"], []) : index => item }

  datasource_uid    = try(each.value.datasource_uid, null)
  coordinates       = each.value.coordinates
  period            = each.value.period
  load_balancer_arn = each.value.load_balancer_arn

  region = each.value.region
}
