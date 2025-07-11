module "this" {
  source = "../../"

  opsgenie_endpoints = [
    {
      name       = "opsgenie"
      api_key    = "xxxxxxxx"
      auto_close = true
    }
  ]
}
