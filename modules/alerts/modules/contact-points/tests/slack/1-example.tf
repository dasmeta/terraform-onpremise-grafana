module "this" {
  source = "../../"

  slack_endpoints = [
    {
      name        = "slack"
      webhook_url = "https://hooks.slack.com/services/xxxxxxxxx"
    }
  ]
}
