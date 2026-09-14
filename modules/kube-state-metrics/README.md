# kube-state-metrics

This child module installs Prometheus Community kube-state-metrics as an
independent Helm release. Its lifecycle does not depend on either metrics
backend and it remains installed when the active collector changes.

The default `fullname_override = "prometheus-kube-state-metrics"` preserves
the Service name previously created by kube-prometheus-stack. The root module
enables exactly one chart `ServiceMonitor` when Prometheus is selected. In
VictoriaMetrics mode that monitor is disabled and the root creates exactly one
native `VMServiceScrape` for the same Service with port `http`,
`honorLabels = true`, and a scoped `max_scrape_size = "32MiB"` endpoint limit.
Both collector-specific scrape paths drop kube-state-metrics Go runtime metrics
matching `^go_.*` before ingestion.
The native object's name has a `-victoria-metrics` suffix so it does not
collide with the same-name object converted from the Prometheus
`ServiceMonitor` during handoff.

Collector-owned values are applied after `extra_configs`: the resource full
name, Service port `8080`, ServiceMonitor activation, Prometheus release
label, selector labels, `honorLabels = true`, and the Go runtime metric filter
cannot be changed through raw overrides. In VictoriaMetrics mode, a caller inline job named exactly
`kube-state-metrics` suppresses the native object and remains responsible for
its own scrape-size limit.

For an existing installation, first apply the root module while Prometheus
remains installed and selected. The root dependency ordering lets the
Prometheus chart remove its bundled kube-state-metrics resources before this
release creates their independent replacement. Verify the exporter and its
`kube_state_*` metrics, then switch the collector in a later apply. Prometheus
may remain enabled during the dual-backend observation window, but it is not
required by this exporter after all application-owned monitor resources have
native VictoriaMetrics replacements.

That ownership handoff must use one complete root-module apply, without
`-target`: the default `prometheus-kube-state-metrics` object fullname is
unchanged while the Helm owner changes from release `prometheus` to release
`kube-state-metrics`. If an interrupted or partial apply reports
`invalid ownership metadata`, rerun the complete apply first. If it remains
blocked, inspect the exact object's `meta.helm.sh/release-*` annotations and
confirm the old Prometheus release no longer renders it before deleting only
that stale object. Never bulk-delete kube-state-metrics resources, PVCs, or
CRDs as recovery.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.17 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.17 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.kube_state_metrics](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Prometheus Community kube-state-metrics Helm chart version. | `string` | `"7.8.1"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether Helm may create the target namespace. | `bool` | `true` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Additional kube-state-metrics chart values applied before selector-owned values. | `any` | `{}` | no |
| <a name="input_fullname_override"></a> [fullname\_override](#input\_fullname\_override) | Full name used for kube-state-metrics Kubernetes resources and Service discovery. | `string` | `"prometheus-kube-state-metrics"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where kube-state-metrics is deployed. | `string` | `"monitoring"` | no |
| <a name="input_prometheus_monitor_enabled"></a> [prometheus\_monitor\_enabled](#input\_prometheus\_monitor\_enabled) | Whether the standalone chart creates a ServiceMonitor for the active Prometheus collector. | `bool` | `true` | no |
| <a name="input_prometheus_release_name"></a> [prometheus\_release\_name](#input\_prometheus\_release\_name) | Prometheus Helm release label selected by the Prometheus custom resource. | `string` | `"prometheus"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | Standalone kube-state-metrics Helm release name. | `string` | `"kube-state-metrics"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | kube-state-metrics Helm release metadata. |
| <a name="output_service_target"></a> [service\_target](#output\_service\_target) | In-cluster kube-state-metrics scrape target. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.17 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.17 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.kube_state_metrics](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Prometheus Community kube-state-metrics Helm chart version. | `string` | `"7.8.1"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether Helm may create the target namespace. | `bool` | `true` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Additional kube-state-metrics chart values applied before selector-owned values. | `any` | `{}` | no |
| <a name="input_fullname_override"></a> [fullname\_override](#input\_fullname\_override) | Full name used for kube-state-metrics Kubernetes resources and Service discovery. | `string` | `"prometheus-kube-state-metrics"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where kube-state-metrics is deployed. | `string` | `"monitoring"` | no |
| <a name="input_prometheus_monitor_enabled"></a> [prometheus\_monitor\_enabled](#input\_prometheus\_monitor\_enabled) | Whether the standalone chart creates a ServiceMonitor for the active Prometheus collector. | `bool` | `true` | no |
| <a name="input_prometheus_release_name"></a> [prometheus\_release\_name](#input\_prometheus\_release\_name) | Prometheus Helm release label selected by the Prometheus custom resource. | `string` | `"prometheus"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | Standalone kube-state-metrics Helm release name. | `string` | `"kube-state-metrics"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | kube-state-metrics Helm release metadata. |
| <a name="output_service_target"></a> [service\_target](#output\_service\_target) | In-cluster kube-state-metrics scrape target. |
<!-- END_TF_DOCS -->
