# Independent kube-state-metrics Design

Date: 2026-08-21
Status: Approved by the user for implementation

## Goal

Keep `kube-state-metrics` installed independently from the Prometheus Helm release, and make the selected collector scrape it without requiring environment-specific configuration.

The required collector behavior is:

- `metrics_collector = "prometheus"`: Prometheus discovers the independent exporter through a `ServiceMonitor`.
- `metrics_collector = "victoria_metrics"`: `vmagent` receives a generated static scrape job for the same exporter Service.
- Changing or disabling `prometheus.enabled` does not destroy the independent `kube-state-metrics` release.

## Architecture

Add an opinionated `modules/kube-state-metrics` wrapper around the Prometheus Community `kube-state-metrics` chart. Version `6.1.0` is the initial default because it is the dependency used by the module's existing `kube-prometheus-stack` chart version `75.8.0`.

The root module owns the shared exporter lifecycle through a grouped `kube_state_metrics` input. It defaults to enabled and is not controlled by `prometheus.enabled` or `metrics_collector`. Operators may explicitly disable it when cluster-state metrics are not required.

The Prometheus chart's bundled dependency is always disabled with:

```yaml
kubeStateMetrics:
  enabled: false
```

This prevents duplicate Deployments and duplicate samples.

## Stable Service contract

The standalone Helm release uses its own Helm release name, but applies a `fullnameOverride` that preserves the existing resource name:

```text
prometheus-kube-state-metrics
```

With the default namespace, the scrape target remains:

```text
prometheus-kube-state-metrics.monitoring.svc.cluster.local:8080
```

The root module derives this hostname from the configured Prometheus release name, the resolved kube-state-metrics namespace, and the fullname override. It is not hard-coded to `monitoring`, so existing namespace overrides continue to work.

During the first migration, the standalone release must not adopt resources owned by the existing `prometheus` Helm release. The root `module.kube_state_metrics` explicitly depends on `module.prometheus`, so Terraform first updates `kube-prometheus-stack` with `kubeStateMetrics.enabled = false` and waits for Helm to delete its bundled Deployment, Service, ServiceAccount, and RBAC resources. Only after that update completes may the standalone Helm release create the same-named resources with its own ownership metadata. The implementation does not use `force`, manual annotation rewrites, or implicit Helm adoption.

The safe upgrade sequence for an existing installation is:

1. Upgrade the module while keeping the current `prometheus.enabled = true` value. This transfers kube-state-metrics ownership to the standalone release.
2. Verify that the independent release and Service are healthy.
3. In a later apply, set `prometheus.enabled = false` if Prometheus itself is no longer required.

If Prometheus was already removed before this module version is applied, there are no old resources to hand off and the standalone release can install directly. A short kube-state-metrics collection gap during the first migration is acceptable; the Service DNS remains unchanged after the migration. If old Helm-owned resources remain unexpectedly, installation must fail visibly instead of taking ownership; the operator removes the stale resources or completes the Prometheus chart update before retrying.

## Collector-specific scraping

### Prometheus mode

The standalone chart creates a `ServiceMonitor` only while Prometheus is the active collector. Its metadata has the exact label `release = <prometheus.release_name>`; with defaults this is `release = prometheus`. The `kube-prometheus-stack` Prometheus CR uses `serviceMonitorSelector.matchLabels.release = <prometheus.release_name>`, so it discovers this object. The ServiceMonitor selects the standalone Service through the chart's `app.kubernetes.io/name` and `app.kubernetes.io/instance` labels. Its endpoint is exactly `port = "http"` with `honorLabels = true`.

No second static Prometheus job is generated, avoiding duplicate collection through both a `ServiceMonitor` and `additionalScrapeConfigs`.

### VictoriaMetrics mode

The standalone chart does not create a `ServiceMonitor`. The root module derives the target with:

```text
<resolved-fullname>.<resolved-namespace>.svc.cluster.local:8080
```

When kube-state-metrics is enabled and VictoriaMetrics is the active collector, the root module prepends this generated job to caller-provided `victoria_metrics.agent.extra_scrape_configs`:

```yaml
- job_name: kube-state-metrics
  honor_labels: true
  max_scrape_size: 32MiB
  static_configs:
    - targets:
        - prometheus-kube-state-metrics.monitoring.svc.cluster.local:8080
```

The target is derived rather than copied literally, so custom release names and namespaces remain supported. Existing caller-provided vmagent scrape jobs are retained after the generated job.

The generated job owns a scoped `max_scrape_size = "32MiB"`. Runtime evidence from `eks-dev` showed a healthy kube-state-metrics endpoint returning `20,282,413` bytes while vmagent rejected it at the default `16,777,216`-byte limit. Applying the limit to this job avoids globally increasing the maximum response accepted from every scrape target.

`job_name = "kube-state-metrics"` is the identity used for duplicate protection. If caller-provided `extra_scrape_configs` already contains that job name (for example, the temporary environment-level configuration used before this module change), the module keeps the caller's job and suppresses the generated one. This avoids duplicate collection and permits a non-disruptive module upgrade. Because the custom job remains authoritative, it must define its own `max_scrape_size` when its response can exceed the vmagent default. Other caller jobs keep their original order after the generated job.

## Input contract

Add a grouped root input with optional attributes:

```hcl
kube_state_metrics = {
  enabled           = true
  chart_version     = "6.1.0"
  release_name      = "kube-state-metrics"
  namespace         = null
  create_namespace  = true
  fullname_override = null
  extra_configs     = {}
}
```

When `namespace` is omitted, it resolves to the Prometheus namespace and then to the root monitoring namespace. When `fullname_override` is omitted, it resolves to `<prometheus.release_name>-kube-state-metrics` for compatibility with the existing Service DNS.

Collector-owned values (`fullnameOverride`, ServiceMonitor activation, selector label, and endpoint settings) are applied after `extra_configs`, preventing raw chart values from accidentally enabling both scrape paths or changing the generated target.

## Data flow

```text
kube-state-metrics Service
  -> Prometheus ServiceMonitor, when metrics_collector = prometheus
  -> vmagent static scrape job, when metrics_collector = victoria_metrics
```

Only the scrape configuration changes when the collector selector changes. The exporter release remains installed, so changing collectors does not remove it.

## Validation and tests

Terraform tests must first demonstrate the missing behavior, then verify:

1. The Prometheus chart disables its bundled kube-state-metrics subchart in every collector mode.
2. The standalone release renders the preserved Service name and chart version.
3. Prometheus mode enables exactly one compatible `ServiceMonitor` and does not add the vmagent job.
4. VictoriaMetrics mode disables the `ServiceMonitor` and injects the generated vmagent job with `honor_labels = true`, `max_scrape_size = "32MiB"`, and the derived target.
5. Caller-provided vmagent scrape jobs remain present, and an existing caller job named `kube-state-metrics` suppresses the generated default so exactly one such job is rendered.
6. `prometheus.enabled = false` does not remove the independent exporter from the Terraform plan.
7. The standalone module depends on the Prometheus module, documenting and enforcing the first-apply ownership handoff.
8. Formatting, validation, focused Terraform tests, and a rendered Helm manifest pass before completion.

## Alternatives considered

### Keep kube-state-metrics inside kube-prometheus-stack

This is the smallest configuration, but deleting the Prometheus release also deletes the exporter. It does not satisfy the requested independent lifecycle.

### Use static scrape jobs for both collectors

This avoids a `ServiceMonitor`, but replaces the existing Prometheus Operator discovery path and duplicates configuration already supported by the standalone chart. The selected design preserves the established Prometheus behavior.

### Migrate to victoria-metrics-k8s-stack

That stack includes exporters and scrape resources, but would also overlap the existing `vmagent`, VictoriaMetrics cluster, Grafana, and operator resources. It remains a separate migration.

## Out of scope

- Separating `node-exporter` from the Prometheus chart.
- Migrating to `victoria-metrics-k8s-stack`.
- Changing VictoriaMetrics storage, retention, or Grafana dashboards.
- Running Prometheus and vmagent against kube-state-metrics simultaneously.
