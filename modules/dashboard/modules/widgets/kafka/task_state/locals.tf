locals {
  matchers = compact([
    var.namespace != "" ? "namespace=\"${var.namespace}\"" : "",
    var.cluster_label != "" && var.cluster != "" ? "${var.cluster_label}=\"${var.cluster}\"" : "",
    var.extra_filters != "" ? var.extra_filters : "",
  ])
  selector = length(local.matchers) > 0 ? "{${join(",", local.matchers)}}" : ""
}
