output "data" {
  value       = module.base.data
  description = "Grafana panel payload"
}

output "expressions" {
  value       = [for metric in local.panel.metrics : metric.expression]
  description = "The PromQL expressions of the rendered panel, used in tests"
}
