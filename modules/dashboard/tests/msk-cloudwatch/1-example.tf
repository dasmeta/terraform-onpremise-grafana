module "this" {
  source = "../.."
  name   = "MSK Dashboard Example"

  rows = [
    {
      type           = "block/msk"
      block_name     = "MSK"
      cluster_names  = ["example-msk-cluster"]
      region         = "eu-central-1"
      datasource_uid = "cloudwatch"
    }
  ]
}
