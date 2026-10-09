module "this" {
  source = "../.."
  name   = "MSK Dashboard Example"

  rows = [
    {
      type            = "block/msk"
      block_name      = "MSK"
      cluster_names   = ["example-msk-cluster"]
      broker_ids      = ["1", "2", "3"]
      consumer_groups = ["example-payments"]
      topics          = ["example-events"]
      region          = "eu-central-1"
      datasource_uid  = "cloudwatch"
    }
  ]
}
