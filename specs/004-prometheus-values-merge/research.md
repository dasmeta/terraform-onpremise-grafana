# Research: Prometheus values merge backport

## Current behavior

`main.tf` passes `merge(var.prometheus.extra_configs,
local.prometheus_remote_write_config)` to `modules/prometheus`. Terraform's
`merge` is shallow. When VictoriaMetrics is enabled, the generated top-level
`prometheus` key replaces the caller's top-level `prometheus` key.

## Chosen correction

Build the effective values map at each required nesting level:

1. Preserve the caller's complete `extra_configs` map.
2. Preserve the caller's `extra_configs.prometheus` map.
3. Preserve the caller's `extra_configs.prometheus.prometheusSpec` map.
4. Add the generated `remoteWrite` list to that `prometheusSpec` map only when
   VictoriaMetrics is enabled.

This preserves scheduling fields such as `nodeSelector` and `tolerations`
without adding a new input or changing generic Helm rendering.

## Rejected alternative

Upgrading to the first published module that contains a nested merge changes
kube-state-metrics and node-exporter ownership. That migration is outside this
backport because existing caller values for the embedded chart components could
stop applying.

## Release note

The source correction can be prepared and tested on the v1.28.0 baseline. The
maintainer must select a release version that communicates the isolated
backport without claiming the unrelated behavior from later 1.28.x releases.
