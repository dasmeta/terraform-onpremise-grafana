# Metrics Collector Selection Design

Date: 2026-08-20
Revised: 2026-08-28
Status: Approved for planning

## Goal

Allow Prometheus and VictoriaMetrics to remain installed together while exactly
one collector is active. When `metrics_collector = "victoria_metrics"`, an
operator-managed `VMAgent` must consume existing Prometheus `PodMonitor` and
`ServiceMonitor` resources, including endpoint authorization, and write samples
to the existing VictoriaMetrics cluster.

The design must preserve the current VictoriaMetrics storage/PVC lifecycle and
provide a one-value rollback to Prometheus.

## Context

The current feature implementation deploys `victoria-metrics-cluster` for
storage and a standalone `victoria-metrics-agent` chart for direct collection.
The standalone agent reads its generated Prometheus scrape file but does not
reconcile `PodMonitor` or `ServiceMonitor` custom resources. This means
application monitoring objects, especially those with Secret-backed
authorization, work with Prometheus Operator but are absent from vmagent unless
their jobs are duplicated manually.

VictoriaMetrics Operator provides the missing reconciliation layer. It converts
Prometheus monitoring objects to VictoriaMetrics scrape objects and continuously
generates the scrape configuration consumed by an operator-managed `VMAgent`.

## User-facing contract

The existing installation and collector selector remains unchanged:

```hcl
prometheus = {
  enabled = true
}

victoria_metrics = {
  enabled = true
}

metrics_collector = "victoria_metrics"
```

- `prometheus.enabled` and `victoria_metrics.enabled` control component
  installation.
- `metrics_collector` selects the only active scraper.
- Both Grafana datasources remain provisioned while their backends are
  installed; VictoriaMetrics is the default datasource in this example.
- Switching the selector back to `prometheus` restores Prometheus collection
  without changing VictoriaMetrics storage.

The VictoriaMetrics object gains a focused operator configuration:

```hcl
victoria_metrics = {
  enabled = true

  operator = {
    chart_version = "0.67.2"
    release_name  = "victoria-metrics-operator"
    extra_configs = {}
  }

  agent = {
    name                 = "victoria-metrics-agent"
    replica_count        = 1
    extra_scrape_configs = []
    extra_configs        = {}
  }
}
```

`operator.extra_configs` remains an escape hatch for operator-chart values.
`agent.extra_configs` applies to the generated `VMAgent` spec, while
`agent.extra_scrape_configs` is rendered as operator-managed inline scrape
configuration for exceptional targets that do not expose a monitor CR.
Secrets and tokens must not be placed in either raw configuration.

`agent.name` is the Kubernetes `VMAgent` custom-resource name, not a Helm
release name. `agent.replica_count` must be a positive integer.

The standalone-agent-specific `agent.chart_version` field is replaced by
`operator.chart_version`. This corrects the still-unreleased collector feature
before it is published; the AWS wrapper must mirror the same interface.

## Architecture

### Shared VictoriaMetrics components

- Keep the existing `victoria-metrics-cluster` Helm release and its vminsert,
  vmselect, vmstorage, retention, resources, service names, and PVC identities.
- Install the official `victoria-metrics-operator` chart version `0.67.2` when
  VictoriaMetrics is installed.
- Order the VictoriaMetrics child module after kube-prometheus-stack and the
  independent kube-state-metrics module so fresh installs cannot race monitor
  CRD creation or a custom exporter namespace.
- Keep Prometheus conversion enabled and enable converter owner references so
  converted resources are removed when their source monitor is removed.
- Keep the operator cluster-scoped so it can discover monitoring objects and
  credentials in application namespaces.
- Keep operator CRD cleanup disabled; changing the active collector must not
  remove shared CRDs or VictoriaMetrics data resources.
- Prometheus monitoring CRDs remain supplied by the installed
  kube-prometheus-stack release during this rollout. Supporting converted
  application monitors with the entire Prometheus release absent requires a
  separately owned Prometheus CRD lifecycle and is out of scope.

Raw `operator.extra_configs` values are applied before selector-owned values.
The module applies conversion enabled and converter ownership enabled under the
chart's `operator` map, then applies the chart's top-level
`watchNamespaces = []`, an empty
`extraArgs["controller.disableReconcileFor"]`, `rbac.create = true`,
`crds.enabled = true`, CRD cleanup disabled, and generated `extraObjects` last.
Unrelated caller `extraArgs` remain supported, but the controller-disable key is
rebuilt by the module because chart `0.67.2` otherwise merges it even when the
converter boolean is false. Caller-provided extra objects are not accepted
through this escape hatch. This prevents a raw override from disabling monitor
conversion, narrowing discovery, deleting CRDs, or removing the active VMAgent.

The protected layer also filters caller `env` entries named `WATCH_NAMESPACE`
or beginning with `VM_ENABLEDPROMETHEUSCONVERTER`, and sets `envFrom = []`.
Unrelated explicit env entries remain supported. This closes alternate
environment-based paths that could narrow namespace watching or disable
conversion without exposing referenced ConfigMap/Secret contents to Terraform.

### Prometheus collector mode

- The Prometheus server is active.
- No operator-managed `VMAgent` resource exists, so converted VictoriaMetrics
  scrape objects do not create a second scraper.
- If VictoriaMetrics is installed, Prometheus keeps the existing remote-write
  validation path to vminsert.
- The VictoriaMetrics Operator may keep converted scrape objects synchronized
  in preparation for a later switch; those objects are inert without VMAgent.

### VictoriaMetrics collector mode

- The Prometheus release remains installed, but its Prometheus server is
  disabled.
- The operator chart renders one `VMAgent` custom resource through its
  `extraObjects` facility. No standalone `victoria-metrics-agent` Helm release
  is installed.
- `VMAgent.spec.selectAllByDefault = true` selects converted `VMPodScrape` and
  `VMServiceScrape` objects across namespaces.
- Raw Pod/Service scrape and namespace selector fields are removed from the
  final VMAgent spec so they cannot narrow discovery and exclude converted
  application monitors or the native KSM object.
- `VMAgent.spec.remoteWrite` points at the existing derived vminsert URL.
- Existing vmagent resource and remote-write queue defaults are represented in
  the `VMAgent` spec.
- Grafana selects the VictoriaMetrics datasource by default.

### Monitor conversion and authorization

The normal application flow is:

```text
PodMonitor / ServiceMonitor
          -> VictoriaMetrics Operator converter
          -> VMPodScrape / VMServiceScrape
          -> generated VMAgent scrape configuration
          -> application metrics endpoint
          -> VictoriaMetrics vminsert
```

The converter preserves `authorization.type` and the Secret key selector from a
Prometheus endpoint. The source Secret remains in the same namespace as the
source monitor. At reconciliation time, the Operator reads that Secret and
embeds the resolved credential in the generated VMAgent configuration Secret in
the VMAgent namespace. This is an Operator runtime artifact: the module does not
copy the source Secret and the token never appears in Terraform input, state,
Helm values, examples, or documentation.

Runtime conversion requires cluster-wide reads of source Secrets. The pinned
chart's generated ClusterRole is broader: it grants wildcard verbs on
`secrets` and `secrets/finalizers`. The Operator service account therefore must
be tightly restricted, and access to both source Secrets and the generated
VMAgent configuration Secret must remain restricted and audited. A narrower
custom RBAC policy is a separate hardening change; this rollout keeps the
chart-owned `rbac.create = true` contract. Secret rotation and
missing/forbidden Secret behavior are live rollout checks.

Consequently, an application that already has a valid `PodMonitor` with
Secret-backed `Authorization: Token ...` does not need a VictoriaMetrics-specific
manual scrape job.

### kube-state-metrics exception

The independent kube-state-metrics endpoint has already been observed returning
about 20 MB, above vmagent's 16 MiB default. VictoriaMetrics Operator v0.74.0
preserves authentication during conversion but does not map Prometheus
`bodySizeLimit` to VictoriaMetrics `max_scrape_size`.

To preserve the existing scoped 32 MiB protection:

- Prometheus mode renders the existing kube-state-metrics `ServiceMonitor`.
- VictoriaMetrics mode disables that Prometheus `ServiceMonitor` and creates one
  native `VMServiceScrape` with `max_scrape_size = "32MiB"` through the operator
  chart's `extraObjects`.
- The old static kube-state-metrics vmagent job is removed.
- A caller-provided transition job named `kube-state-metrics` suppresses the
  native object until that override is removed, preserving duplicate avoidance;
  the caller remains responsible for its scrape-size limit.
- The native scrape object and converted application monitors are selected by
  the same operator-managed VMAgent.

This is the only built-in native scrape exception. Application monitors remain
source-owned and converter-driven.

The native object is created in the kube-state-metrics namespace and uses:

- `spec.namespaceSelector.matchNames` containing that same resolved namespace;
- the Service selector labels `app.kubernetes.io/name = kube-state-metrics` and
  `app.kubernetes.io/instance = <standalone release name>`;
- endpoint port `http`, `honorLabels = true`, and endpoint
  `max_scrape_size = "32MiB"`;
- names and selectors derived from the existing configurable release name,
  fullname override, and namespace rather than fixed environment values.

## Ownership boundaries

### Base module

`terraform-onpremise-grafana` owns:

- the operator Helm release and CRDs;
- the selector-controlled `VMAgent` object;
- the existing VictoriaMetrics cluster destination;
- the collector-specific kube-state-metrics monitor object;
- prevention of simultaneous Prometheus and VMAgent collection;
- Terraform tests and rollout documentation.

### AWS wrapper

`terraform-aws-grafanav12` mirrors and forwards the revised
`victoria_metrics.operator` and `victoria_metrics.agent` inputs, keeps
`metrics_collector` unchanged, and updates its tests and examples. It does not
duplicate operator resources or collection logic.

### Application charts

Applications continue to own:

- their metrics endpoint;
- `PodMonitor` or `ServiceMonitor` selectors, path, port, and interval;
- endpoint authorization and the referenced Secret;
- application-specific token creation and rotation.

No application source-code change is required when its existing monitor already
describes a healthy metrics endpoint and valid credentials.

## Lifecycle and rollout

The safe migration uses two applies while both backends remain enabled:

1. Select Prometheus. Install the operator, remove the old standalone vmagent,
   and confirm source monitors are converted while Prometheus continues
   collecting.
2. Select VictoriaMetrics. Create the operator-managed VMAgent and disable the
   Prometheus server in the same apply.

The exactly-one-scraper guarantee describes converged module state. Terraform
cannot atomically coordinate in-place changes across the independent Prometheus
and Operator Helm releases, so the second apply may contain a bounded overlap or
collection gap. Before switching, confirm the Operator is ready, source monitors
are converted, no pre-existing VMAgent selects those objects, and Prometheus
remote-write queues are drained. The executable drain gate is
`prometheus_remote_storage_samples_pending == 0` for at least two scrape
intervals, with no increase in remote-write failed or retried sample counters.
After convergence, verify VMAgent targets and roll back immediately if required
metrics are absent.

After the switch, verify converted scrape objects, healthy VMAgent targets,
remote-write health, Kubernetes dashboard metrics, and at least one
authorization-protected application metric.

Rollback changes only `metrics_collector` to `prometheus`. Before applying it,
wait until `vmagent_remotewrite_pending_data_bytes` is zero and remote-write
errors are clear; removing an agent backed by ephemeral queue storage can
discard pending samples. The module then removes the VMAgent object and restores
the Prometheus server. Rollback may also have a bounded overlap or gap during
convergence, but it does not delete the VictoriaMetrics cluster or vmstorage
PVCs.

## Error handling and safeguards

- Selecting a collector whose backend is disabled remains a Terraform error.
- The module renders exactly one active scraper in every converged valid mode;
  bounded overlap or absence during a selector apply is explicitly documented.
- Converter ownership is enabled to prevent stale converted targets after a
  source monitor is removed.
- The Operator conversion controls, CRD/RBAC safety controls, generated objects,
  and VMAgent destination, selectors, positive replica count, and scrape object
  ownership are selector-owned values and cannot be silently removed by raw
  overrides.
- Helm rendering must prove that authorization Secret selectors survive monitor
  conversion-compatible input shapes; live rollout must prove the target is
  healthy before Prometheus is considered removable.
- Operator or VMAgent rollout failures leave VictoriaMetrics storage untouched.

## Validation and testing

Automated validation covers:

1. Both backend flags with Prometheus selected: Prometheus active, no VMAgent,
   operator installed, and remote write retained.
2. Both backend flags with VictoriaMetrics selected: Prometheus server disabled,
   one VMAgent CR rendered, and VictoriaMetrics datasource defaulted.
3. Operator chart version, converter enablement, converter ownership, CRD cleanup
   safety, and derived vminsert URL.
4. Application monitor conversion support without application Secret values in
   rendered Terraform/Helm configuration.
5. Prometheus kube-state-metrics `ServiceMonitor` versus VictoriaMetrics native
   `VMServiceScrape`, including the 32 MiB scoped limit and no duplicate job.
6. Existing storage/PVC settings unchanged between collector modes.
7. AWS wrapper input parity and forwarding.
8. Terraform formatting, validation, focused tests, and Helm template rendering.

Live validation covers:

- source `PodMonitor` and converted `VMPodScrape` presence;
- VMAgent target health and last scrape error;
- custom application metric availability in VictoriaMetrics;
- kube-state, kubelet/cAdvisor, network, and volume dashboard continuity;
- no simultaneous Prometheus and VMAgent scrape of the same application target;
- remote-write queue and error counters.
- source Secret rotation, missing/forbidden Secret errors, and restricted access
  to the generated VMAgent configuration Secret;
- absence of a pre-existing VMAgent or overlapping native scrape object that
  selects the same target.

## Alternatives considered

### Full victoria-metrics-k8s-stack replacement

The stack chart provides Operator, VMAgent, exporters, scrape objects, storage,
dashboards, and rules. It is not selected because it would overlap the existing
VictoriaMetrics cluster wrapper and create a larger migration of service names,
exporter ownership, chart values, and PVC behavior.

### Standalone vmagent plus manual jobs

This preserves the current implementation but requires every application
monitor, Secret, and future update to be duplicated into central scrape
configuration. It does not satisfy automatic `PodMonitor`/`ServiceMonitor`
support.

### Global 32 MiB vmagent scrape limit

This would allow the converted kube-state-metrics monitor to work, but weakens
the response-size guard for every target. A single native `VMServiceScrape` keeps
the larger limit scoped to the exporter that needs it.

## Out of scope

- Replacing the existing VictoriaMetrics cluster with an operator-managed
  `VMCluster`.
- Removing the entire kube-prometheus-stack release and independently migrating
  every exporter/rule in the same change.
- Independently owning Prometheus `PodMonitor`/`ServiceMonitor` CRDs after the
  entire kube-prometheus-stack release is removed.
- Running Prometheus and VMAgent as a supported simultaneous converged mode;
  only the documented bounded handoff overlap is accepted.
- Migrating or rotating application API tokens.
- Changing VictoriaMetrics retention or vmstorage PVC identities.
