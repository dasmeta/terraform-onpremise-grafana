# VictoriaMetrics Native Stack Selection Design

**Date:** 2026-08-31

**Status:** Approved architecture; implementation pending

## Context

The module currently supports selecting Prometheus or VictoriaMetrics as the
active scraper, but VictoriaMetrics still depends on resources supplied by
`kube-prometheus-stack`:

- Prometheus Operator CRDs for `PodMonitor` and `ServiceMonitor` conversion;
- kubelet and cAdvisor discovery;
- the bundled node-exporter and its monitor;
- monitor resources created by module-owned components.

Consequently, `metrics_collector = "victoria_metrics"` still requires
`prometheus.enabled = true`. This is a migration mode, not a standalone
VictoriaMetrics stack.

## Goal

Make the selected metrics stack independently usable:

- Prometheus-only:
  `metrics_collector = "prometheus"`, `prometheus.enabled = true`, and
  `victoria_metrics.enabled = false` is valid.
- VictoriaMetrics-only:
  `metrics_collector = "victoria_metrics"`,
  `victoria_metrics.enabled = true`, and `prometheus.enabled = false` is valid.
- Dual-backend migration:
  both backends may remain installed while exactly one collector actively
  scrapes and exactly one Grafana metrics datasource is the default.

Standalone VictoriaMetrics must not require or create
`monitoring.coreos.com` resources. It uses only VictoriaMetrics Operator CRDs.

## Scope

This design changes only `terraform-onpremise-grafana` and its child modules,
tests, and documentation.

The following are explicitly outside this implementation:

- the AWS wrapper module;
- environment YAML;
- application Helm charts and values;
- migration of application-owned `PodMonitor`, `ServiceMonitor`, or
  `PrometheusRule` resources;
- automatic translation of caller-provided Prometheus additional scrape jobs;
- replacement of the bundled Prometheus Alertmanager or chart-provided
  `PrometheusRule` objects;
- automatic deletion of old Prometheus Operator CRDs;
- Git staging, commits, pushes, or pull requests.

Applications are responsible for creating `VMPodScrape`, `VMServiceScrape`,
and `VMRule` resources before Prometheus compatibility is removed.
Caller-owned jobs move explicitly from
`prometheus.additional_scrape_configs` to
`victoria_metrics.agent.extra_scrape_configs`; the module does not copy them
because jobs may have backend-specific discovery and authentication behavior.

## Architecture

### Selected backend and active collector

The existing inputs keep separate responsibilities:

- `prometheus.enabled` controls installation of `kube-prometheus-stack`.
- `victoria_metrics.enabled` controls installation of VictoriaMetrics Cluster
  and VictoriaMetrics Operator.
- `metrics_collector` selects the single active scraper and default Grafana
  metrics datasource.

The selected collector must be installed. Installing both backends remains
valid for migration, but does not activate two scrapers.

### Shared exporters

Exporters are not metrics databases and are not owned by either collector.
They expose Prometheus-format metrics that either collector can scrape.

#### kube-state-metrics

The existing independent kube-state-metrics child module remains installed
according to `kube_state_metrics.enabled` regardless of the selected backend.

- Prometheus mode creates its `ServiceMonitor`.
- VictoriaMetrics mode disables that `ServiceMonitor` and creates a native
  `VMServiceScrape`.

#### node-exporter

Add an independent node-exporter child module with a root configuration object
whose defaults preserve current node metrics behavior. Disable the bundled
node-exporter in `kube-prometheus-stack` so exporter lifecycle no longer
depends on Prometheus installation.

- Prometheus mode creates one `ServiceMonitor` for the independent exporter.
- VictoriaMetrics mode creates one native `VMServiceScrape` and no
  `ServiceMonitor`.

The transition must avoid duplicate resource ownership and duplicate scraping.
The standalone release is created only after the Prometheus release has
disabled or removed its bundled exporter.

### Kubernetes node metrics

Prometheus mode keeps kubelet and cAdvisor discovery from
`kube-prometheus-stack`.

VictoriaMetrics mode creates native, selector-owned `VMNodeScrape` objects for:

- kubelet `/metrics`;
- cAdvisor `/metrics/cadvisor`;
- resource metrics `/metrics/resource` when enabled by the module contract.

The scrape objects authenticate with the VMAgent service-account token and use
the mounted Kubernetes CA. Their relabeling must preserve the labels and job
identity required by existing dashboards. Metric filtering must retain the
current container, network, filesystem, volume, and pod resource metrics.

`VMAgent` selectors for module-owned node, pod, and service scrape objects are
selector-owned so raw overrides cannot silently exclude generated targets.

### VictoriaMetrics Operator CRDs

The VictoriaMetrics Operator Helm release installs and upgrades its own CRDs
before Helm maps generated custom resources. In standalone VictoriaMetrics
mode:

- `operator.disable_prometheus_converter = true`;
- converter ownership is disabled;
- no Prometheus-converter environment override may re-enable conversion;
- generated resources use only `operator.victoriametrics.com/v1beta1` kinds.

When Prometheus is installed during migration, conversion remains enabled so
existing application `PodMonitor` and `ServiceMonitor` resources can continue
feeding the selected VMAgent until applications create native VM resources.

The module does not delete old Prometheus CRDs. Deleting CRDs can delete all
custom resources of those kinds and is therefore a separate, explicit cluster
cleanup after migration verification.

### Module-owned monitoring resources

Any module-owned chart that currently creates `ServiceMonitor` must be
collector-aware.

- Prometheus mode may create the existing Prometheus monitor.
- VictoriaMetrics-only mode must suppress Prometheus monitor resources.
- Where the module currently expects component self-metrics, it creates the
  equivalent native `VMServiceScrape` using the chart's stable Service labels
  and named metrics port.

This applies to the enabled module-owned Tempo and Loki components. Grafana's
module default ServiceMonitor remains disabled.

### Tempo metrics-generator

An omitted Tempo metrics-generator remote-write URL resolves from the selected
collector:

- Prometheus mode uses the selected Prometheus write endpoint.
- VictoriaMetrics mode uses the derived cluster `vminsert` endpoint.

An explicitly supplied remote URL remains caller-owned and is preserved.

### Alerting boundary

The module's alert rules, contact points, and notification policies are Grafana
resources and remain available with either metrics datasource. They do not
depend on the Alertmanager bundled with `kube-prometheus-stack`.

VM-only mode does not install Prometheus Alertmanager, `VMAlert`, or a separate
Alertmanager replacement. Consumers that directly use the stack's
Alertmanager or its chart-provided `PrometheusRule` resources must migrate
those workloads separately before disabling Prometheus.

### Grafana datasource

Datasource provisioning remains installation-aware:

- only installed backends receive a datasource;
- the datasource corresponding to `metrics_collector` is the only default;
- VM-only mode provisions no Prometheus datasource;
- the VictoriaMetrics datasource continues using the Prometheus-compatible
  `vmselect` query endpoint and stable UID `victoriametrics`.

## Mode Contract

### Prometheus-only

- `kube-prometheus-stack` is installed and its Prometheus server scrapes.
- VictoriaMetrics Cluster, Operator, and VMAgent are absent.
- shared exporters are installed independently and discovered through
  Prometheus `ServiceMonitor` resources.
- kubelet and cAdvisor are collected through the stack's existing monitor.

### VictoriaMetrics-only

- `kube-prometheus-stack` is absent.
- VictoriaMetrics Cluster, Operator, and VMAgent are installed.
- the Operator installs only VictoriaMetrics CRDs and does not run the
  Prometheus converter.
- shared exporters are discovered through native `VMServiceScrape` resources.
- kubelet, cAdvisor, and resource metrics are discovered through native
  `VMNodeScrape` resources.
- no generated object uses `monitoring.coreos.com`.

### Dual-backend migration

- both storage backends may be installed.
- only the selected collector scrapes.
- when VictoriaMetrics is selected and Prometheus remains installed, converter
  compatibility remains available for application-owned Prometheus monitors.
- switching only the selector does not delete VictoriaMetrics storage.

## Configuration and Override Safety

Selector-owned settings are applied after raw chart overrides. Callers cannot
use `extra_configs` to:

- enable both active scrapers;
- re-enable a bundled shared exporter;
- create a Prometheus monitor in VM-only mode;
- disable required VictoriaMetrics CRDs;
- narrow VMAgent selectors so generated native scrape objects are ignored;
- redirect selector-owned remote write to another backend.

Non-protected resource, scheduling, image, and unrelated chart options remain
caller-configurable.

## Migration

1. Upgrade to the module version while Prometheus remains installed.
2. Verify independent kube-state-metrics and node-exporter collection.
3. Select VictoriaMetrics while both backends remain installed.
4. Migrate application monitors to `VMPodScrape`/`VMServiceScrape` and verify
   authenticated application metrics in VictoriaMetrics.
5. Set `prometheus.enabled = false` and apply.
6. Verify VMAgent targets, kubelet/cAdvisor metrics, exporter metrics, Grafana
   dashboards, alerts, and KEDA queries.
7. Remove old Prometheus CRDs only as a separate manual operation after no
   resources or rollback path depend on them.

Rollback re-enables Prometheus and selects it as the collector. Existing
VictoriaMetrics PVCs and historical samples remain untouched unless the caller
explicitly removes the VictoriaMetrics backend or its storage.

## Verification

Automated verification must cover:

- Terraform formatting and validation;
- Prometheus-only, VictoriaMetrics-only, and dual-backend root plans;
- failure when the selected backend is disabled;
- VM-only Operator values with converter disabled and VM CRDs enabled;
- absence of Prometheus CR kinds in VM-only generated objects;
- exact native KSM and node-exporter `VMServiceScrape` objects;
- exact kubelet, cAdvisor, and resource `VMNodeScrape` objects;
- independent exporter installation and monitor selection in both modes;
- selector-owned override precedence;
- VM-only Grafana datasource and Tempo remote-write resolution;
- a fresh-cluster Helm render proving CRDs precede `VMAgent`,
  `VMServiceScrape`, and `VMNodeScrape` mapping.

Live rollout verification must check healthy VMAgent targets and representative
metrics from each path:

- `kube_deployment_status_replicas_available`;
- `container_cpu_usage_seconds_total`;
- `container_memory_working_set_bytes`;
- `container_network_receive_bytes_total`;
- `kubelet_volume_stats_used_bytes`;
- `node_filesystem_avail_bytes`;
- at least one authenticated application metric supplied through an
  application-owned native VM scrape resource.

## Risks and Controls

- **Missing application metrics:** application migration is an explicit gate
  before disabling Prometheus.
- **Missing node or container metrics:** native VMNodeScrape and independent
  node-exporter tests are required before VM-only rollout.
- **Duplicate samples during migration:** only one collector is active, and
  generated monitor paths are mutually exclusive.
- **Fresh-cluster CRD ordering:** render tests and Helm dependencies verify the
  Operator CRDs before custom resources are mapped.
- **Accidental data deletion:** the module never automatically deletes
  Prometheus CRDs or VictoriaMetrics storage.
