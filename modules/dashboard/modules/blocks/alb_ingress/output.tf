output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : "AWS ALB" }
    ],
    [
      { type : "alb_ingress/connections", load_balancer_arn = var.load_balancer_arn, region = var.region, datasource_uid = var.datasource_uid },
      { type : "alb_ingress/request_count", load_balancer_arn = var.load_balancer_arn, region = var.region, datasource_uid = var.datasource_uid },
      { type : "alb_ingress/target_response_time", load_balancer_arn = var.load_balancer_arn, region = var.region, datasource_uid = var.datasource_uid },
      { type : "alb_ingress/target_http_response", load_balancer_arn = var.load_balancer_arn, region = var.region, datasource_uid = var.datasource_uid }
    ],
  ]
}
