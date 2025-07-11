module "this" {
  source = "../../"

  notifications = {
    contact_point   = "slack"
    group_by        = ["..."]
    group_interval  = "10m"
    repeat_interval = "1h"
  }

  depends_on = [module.contact_points]
}
