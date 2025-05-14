output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : "Cloudwatch metrics" }
    ],
    [
      { type : "cloudwatch/instance_cpu", width : 8, height : 6, datasource : { type : "cloudwatch", uid : "cloudwatch" } },
      { type : "cloudwatch/instance_disk", width : 8, height : 6, datasource : { type : "cloudwatch", uid : "cloudwatch" } },
      { type : "cloudwatch/instance_network", width : 8, height : 6, datasource : { type : "cloudwatch", uid : "cloudwatch" } },
    ],
  ]
}
