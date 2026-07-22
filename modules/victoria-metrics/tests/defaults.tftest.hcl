run "default_values_include_datasource_resilience_args" {
  command = plan

  assert {
    condition     = jsondecode(helm_release.victoria_metrics.values[0]).vminsert.extraArgs.replicationFactor == 2
    error_message = "vminsert must default replicationFactor to 2."
  }

  assert {
    condition     = jsondecode(helm_release.victoria_metrics.values[0]).vmselect.extraArgs.replicationFactor == 2
    error_message = "vmselect must default replicationFactor to 2."
  }

  assert {
    condition     = jsondecode(helm_release.victoria_metrics.values[0]).vmselect.extraArgs["dedup.minScrapeInterval"] == "1ms"
    error_message = "vmselect must default dedup.minScrapeInterval to 1ms."
  }

  assert {
    condition     = jsondecode(helm_release.victoria_metrics.values[0]).vmselect.extraArgs["search.skipSlowReplicas"] == true
    error_message = "vmselect must default search.skipSlowReplicas to true."
  }
}
