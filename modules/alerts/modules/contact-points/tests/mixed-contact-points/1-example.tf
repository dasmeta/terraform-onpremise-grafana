module "this" {
  source = "../../"

  opsgenie_endpoints = [
    {
      name       = "Dev OpsGenie"
      api_key    = "asdARdszgads1235fsdad"
      auto_close = true
    },
    {
      name    = "Stage OpsGenie"
      api_key = "werARdsswefazgads12dad"
    }
  ]
  slack_endpoints = [
    {
      name        = "Dev Notifications"
      webhook_url = "https://hooks.slack.com/services/T6safsfFSF2352SFzdn"
    }
  ]
}
