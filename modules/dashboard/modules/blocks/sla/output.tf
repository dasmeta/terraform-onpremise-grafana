output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : "SLA/SLO" }
    ],
    var.sla_ingress_type == "nginx" ?
    [
      { type = "sla-slo-sli/nginx_availability", filter = var.filter, width = 3, height = var.height, datasource_uid = var.datasource_uid },
      { type = "sla-slo-sli/nginx_latency", filter = var.filter, width = 3, height = var.height, datasource_uid = var.datasource_uid },
      { type = "sla-slo-sli/nginx_availability", filter = var.filter, width = 8, height = var.height, histogram : true, datasource_uid = var.datasource_uid },
      { type = "sla-slo-sli/nginx_latency", filter = var.filter, width = 10, height = var.height, histogram : true, datasource_uid = var.datasource_uid }
    ] :
    [
      { type = "sla-slo-sli/alb_availability", width = 12, height = var.height, load_balancer_arn = var.load_balancer_arn, datasource_uid = var.datasource_uid, region = var.region },
      { type = "sla-slo-sli/alb_latency", width = 12, height = var.height, load_balancer_arn = var.load_balancer_arn, datasource_uid = var.datasource_uid, region = var.region }
    ]
  ]
}
