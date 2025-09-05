
output "rule_groups" {
  value       = try(module.alert_rules[0].rule_group, {})
  description = "The grafana alert rule groups"
}

output "contact_points" {
  value       = try(module.contact_points[0].contact_points, {})
  description = "The grafana contact points"
}

output "notification_policies" {
  value       = try(module.notifications[0].notification_policies, {})
  description = "The grafana notification policies"
}
