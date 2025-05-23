locals {
  # Use regex to extract everything after 'loadbalancer/' in the ARN
  load_balancer_identifier = (
    can(regex(".*loadbalancer/(.*)", var.load_balancer_arn))
    ? regex(".*loadbalancer/(.*)", var.load_balancer_arn)[0]
    : "default-load-balancer" # Default value if ARN is empty or invalid
  )
}
