module "this" {
  source      = "../../."
  data_source = { "type" : "prometheus", "uid" : "prometheus" }
  name        = "awg prod dashboard"
  rows = [
    { "name" : "dev-deployment1", "namespace" : "dev", "type" : "block/service" },
    { "name" : "dev-deployment2", "namespace" : "dev", "type" : "block/service" },
    { "name" : "dev-deployment3", "namespace" : "dev", "type" : "block/service" },
  ]
}
