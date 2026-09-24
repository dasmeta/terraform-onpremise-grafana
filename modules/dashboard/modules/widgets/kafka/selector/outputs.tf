locals {
  matchers = compact([
    var.namespace != "" ? "namespace=\"${var.namespace}\"" : "",
    var.cluster_label != "" && var.cluster != "" ? "${var.cluster_label}=\"${var.cluster}\"" : "",
    var.extra_filters != "" ? var.extra_filters : "",
  ])
}

output "matchers" {
  description = "PromQL matchers without surrounding braces"
  value       = local.matchers
}

output "selector" {
  description = "PromQL selector including braces, or empty when there are no matchers"
  value       = length(local.matchers) > 0 ? "{${join(",", local.matchers)}}" : ""
}
