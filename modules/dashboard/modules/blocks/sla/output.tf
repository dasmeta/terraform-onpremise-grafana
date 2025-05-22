output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : "SLA/SLO" }
    ],
    var.sla_ingress_type == "nginx" ?
    [
      { type = "sla-slo-sli/nginx_main", width : 5, height : 6, balancer_name = var.balancer_name, datasource_uid = var.datasource_uid },
      { type = "sla-slo-sli/nginx_latency", width : 5, height : 6, balancer_name = var.balancer_name, datasource_uid = var.datasource_uid },
      { type = "sla-slo-sli/nginx_latency", width : 14, height : 6, balancer_name = var.balancer_name, histogram : true, datasource_uid = var.datasource_uid }
    ] :
    [
      { type = "sla-slo-sli/alb_availability", width : 5, height : 6, load_balancer_arn = var.load_balancer_arn, datasource_uid = var.datasource_uid, region = var.region },
      { type = "sla-slo-sli/alb_latency", width : 5, height : 6, load_balancer_arn = var.load_balancer_arn, datasource_uid = var.datasource_uid, region = var.region }
    ]
  ]
}
