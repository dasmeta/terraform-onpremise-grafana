module "this" {
  source = "../../"

  notifications = {
    contact_point   = "slack"
    group_by        = ["alertname"]
    group_interval  = "1m"
    repeat_interval = "1m"

    policies = [
      {
        contact_point = "opsgenie"
        matchers      = [{ label = "priority", match = "=", value = "P1" }]
      },
      {
        contact_point = "slack"
      }
    ]
  }

  depends_on = [module.opsgenie_contact_points, module.slack_contact_points]
}
