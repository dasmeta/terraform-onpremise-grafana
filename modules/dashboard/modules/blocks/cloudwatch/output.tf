output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : "Cloudwatch metrics" }
    ],
    [
      { type : "cloudwatch/instance_cpu", datasource_uid : var.datasource_uid, region : var.region },
      { type : "cloudwatch/instance_disk", datasource_uid : var.datasource_uid, region : var.region },
      { type : "cloudwatch/instance_network", datasource_uid : var.datasource_uid, region : var.region },
    ],
  ]
}
