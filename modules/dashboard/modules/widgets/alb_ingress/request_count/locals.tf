locals {
  load_balancer_identifier = (
    length(var.load_balancer_arn) > 0 && can(regex(".*?/(.*?)/.*", var.load_balancer_arn))
    ? regex(".*?/(.*?)/.*", var.load_balancer_arn)[0]
    : "default-load-balancer" # Default value if ARN is empty or invalid
  )
}
