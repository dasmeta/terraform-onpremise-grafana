locals {
  extra_relabel_configs = concat(
    try(var.configs.promtail.extra_relabel_configs, []),
    length(var.configs.promtail.ignored_namespaces) > 0 ?
    [{
      action        = "drop"
      source_labels = ["__meta_kubernetes_namespace"]
      regex         = format("(%s)", join("|", var.configs.promtail.ignored_namespaces))
    }] :
    [],
    length(var.configs.promtail.ignored_containers) > 0 ?
    [{
      action        = "drop"
      source_labels = ["__meta_kubernetes_pod_container_name"]
      regex         = format("(%s)", join("|", var.configs.promtail.ignored_containers))
    }] :
    []
  )
  extra_relabel_configs_yaml = yamlencode(local.extra_relabel_configs)
  extra_scrape_configs_yaml  = length(var.configs.promtail.extra_scrape_configs) > 0 ? yamlencode(var.configs.promtail.extra_scrape_configs) : ""
}

output "scrape_configs" {
  value = local.extra_scrape_configs_yaml
}
