# Feature Specification: Selectable Metrics Collectors

**Feature Branch**: `004-metrics-collector-selection`
**Created**: 2026-08-20
**Revised**: 2026-08-28
**Status**: Approved for planning
**Input**: User description: "Install Prometheus and VictoriaMetrics together, select which one collects metrics, and test VictoriaMetrics while Prometheus remains active."

## User Scenarios & Testing

### User Story 1 - Install both backends with Prometheus active (Priority: P1)

An operator wants to install both metrics backends while keeping Prometheus as the only active scraper, so VictoriaMetrics can be validated without duplicate collection.

**Why this priority**: This is the safe rollout path for existing Prometheus users and allows VictoriaMetrics storage and query behavior to be tested before switching collectors.

**Independent Test**: Enable both backend installations, select Prometheus, apply the module, and verify that Prometheus collects while VictoriaMetrics receives a copy and no VictoriaMetrics agent scrapes the same targets.

**Acceptance Scenarios**:

1. **Given** both backend installations are enabled and the collector selection is `prometheus`, **When** the monitoring stack is applied, **Then** Prometheus is the active scraper and VictoriaMetrics remains available as a receiving/query backend.
2. **Given** Prometheus is active and VictoriaMetrics is installed, **When** metrics are generated, **Then** the same metric data can be queried from VictoriaMetrics without a second scraper collecting the same targets.

### User Story 2 - Switch active collection to VictoriaMetrics (Priority: P2)

An operator wants to change the collector selection to VictoriaMetrics after validation, so VictoriaMetrics can collect directly while Prometheus remains available for a controlled transition.

**Why this priority**: Direct VictoriaMetrics collection is the requested capability and the reason for introducing the selector.

**Independent Test**: Change the selection to `victoria_metrics`, apply the module, and verify that the VictoriaMetrics agent collects and writes new samples while Prometheus no longer scrapes the same targets.

**Acceptance Scenarios**:

1. **Given** both backend installations are enabled and the collector selection changes to `victoria_metrics`, **When** the stack is applied, **Then** the VictoriaMetrics collector becomes active and Prometheus scraping is disabled.
2. **Given** historical samples already exist in VictoriaMetrics, **When** the active collector changes, **Then** historical samples remain queryable and only the transition interval has no samples.

### User Story 3 - Configure a valid and understandable rollout (Priority: P3)

An operator wants invalid collector choices and incomplete installation combinations to be clearly identified, so a rollout cannot silently produce a stack with no active collector.

**Why this priority**: Clear validation prevents an ambiguous production configuration while keeping the common configuration simple.

**Independent Test**: Render plans for valid selections and invalid/missing backend combinations and verify deterministic validation behavior and documentation.

**Acceptance Scenarios**:

1. **Given** a selector value other than `prometheus` or `victoria_metrics`, **When** Terraform validates inputs, **Then** it reports a clear input error.
2. **Given** a selected backend is not installed, **When** Terraform evaluates the configuration, **Then** it reports which backend must be enabled instead of silently deploying no collector.

### User Story 4 - Keep cluster-state metrics independent (Priority: P1)

An operator wants `kube-state-metrics` to remain installed when Prometheus is disabled, while only the selected collector scrapes it.

**Why this priority**: Application replica and resource-request dashboards require kube-state-metrics even when VictoriaMetrics is the only metrics backend.

**Independent Test**: Plan a dual-backend configuration with VictoriaMetrics selected and verify that the standalone exporter remains installed, its Prometheus `ServiceMonitor` is disabled, and the operator-managed VMAgent receives exactly one native kube-state-metrics scrape object.

**Acceptance Scenarios**:

1. **Given** `metrics_collector = "prometheus"`, **When** the stack is rendered, **Then** the independent kube-state-metrics release creates a Prometheus-compatible `ServiceMonitor` and vmagent is absent.
2. **Given** `metrics_collector = "victoria_metrics"`, **When** the stack is rendered, **Then** the `ServiceMonitor` is disabled and a native `VMServiceScrape` targets the independent Service through the operator-managed VMAgent.
3. **Given** both backends remain installed and VictoriaMetrics is selected, **When** the Prometheus server is disabled, **Then** kube-state-metrics remains installed independently.
4. **Given** the kube-state-metrics response is larger than vmagent's default 16 MiB scrape limit, **When** VictoriaMetrics is selected, **Then** the native scrape object accepts responses up to 32 MiB without raising the limit for unrelated targets.

### User Story 5 - Reuse application monitor objects with VictoriaMetrics (Priority: P1)

An operator wants VictoriaMetrics to consume existing Prometheus `PodMonitor`
and `ServiceMonitor` resources, including Secret-backed endpoint authorization,
so applications do not need collector-specific duplicate scrape jobs.

**Why this priority**: Application metrics required by dashboards, alerts, and
autoscaling remain incomplete while standalone vmagent ignores monitor CRDs.

**Independent Test**: Keep both backends installed, select VictoriaMetrics,
render the operator-managed collector, and verify that an authorization-enabled
`PodMonitor` is converted to `VMPodScrape` and becomes a healthy VMAgent target.

**Acceptance Scenarios**:

1. **Given** an application has a valid `PodMonitor`, **When** VictoriaMetrics is selected, **Then** VictoriaMetrics Operator creates and synchronizes a corresponding `VMPodScrape`.
2. **Given** the monitor endpoint references a Secret for `Authorization`, **When** it is converted, **Then** the authorization type and Secret key selector are preserved without copying the token into module configuration.
3. **Given** Prometheus is selected again, **When** the module is applied, **Then** the operator-managed VMAgent is removed and Prometheus resumes collection without deleting VictoriaMetrics storage.

### Edge Cases

- Both backend releases are enabled while only one collector is active; the inactive backend must not scrape the same targets.
- Only Prometheus is installed and selected; the stack must continue to work without VictoriaMetrics.
- VictoriaMetrics is selected while the Prometheus release is disabled; the module must reject this operator-conversion mode until Prometheus monitoring CRDs have an independent owner.
- The selector is changed while persistent VictoriaMetrics storage remains present; existing data must not be deleted.
- The selector is changed while no new samples are being written; dashboards and alerts may show a temporary no-data interval, but the transition must not backfill or corrupt history.
- Custom VictoriaMetrics values must continue to override generated defaults without changing the derived in-cluster write endpoint.
- The active vmagent may build a remote-write backlog; resource tuning must not silently change the chart's persistent-queue volume behavior.
- An existing environment may already provide a kube-state-metrics VMAgent extra job; that caller-owned transition job must suppress the native object instead of creating duplicate collection until the override is removed.
- Existing kube-prometheus-stack installations own same-named kube-state-metrics resources; the first module upgrade must remove the bundled subchart before creating the standalone release.
- A cluster with many Kubernetes objects may produce a kube-state-metrics payload larger than vmagent's default 16 MiB limit; the native scrape object must retain enough scoped headroom to ingest it.
- Prometheus and VictoriaMetrics operators may coexist; converted scrape objects must remain inert while no VMAgent resource is active.
- A source monitor may be updated or deleted; the converted VictoriaMetrics object must follow its lifecycle instead of becoming a stale target.
- Application monitor authorization may reference a Secret in the application namespace; the module must not require the Secret value in Terraform input or state, while the Operator is expected to resolve it into the generated VMAgent configuration Secret at runtime.
- Prometheus `bodySizeLimit` is not converted to VictoriaMetrics `max_scrape_size`; kube-state-metrics needs a native VictoriaMetrics scrape object to retain its scoped 32 MiB limit.
- On a fresh cluster without VictoriaMetrics CRDs, the Operator Helm release must install CRDs through Helm's pre-install CRD path before mapping generated `VMAgent` and `VMServiceScrape` objects.

## Requirements

### Functional Requirements

- **FR-001**: The module MUST expose a collector selection with exactly two supported values: `prometheus` and `victoria_metrics`.
- **FR-002**: The collector selection MUST default to `prometheus`.
- **FR-003**: The module MUST allow both backend releases to be installed while activating only the selected collector.
- **FR-004**: In Prometheus mode, Prometheus MUST collect metrics and, when VictoriaMetrics is installed, MUST be able to forward a copy to VictoriaMetrics for validation and durable storage.
- **FR-005**: In VictoriaMetrics mode, a VictoriaMetrics-compatible collector MUST discover Kubernetes targets and write samples to the configured VictoriaMetrics cluster.
- **FR-006**: In VictoriaMetrics mode, Prometheus MUST NOT collect the same Kubernetes targets as the active VictoriaMetrics collector.
- **FR-007**: Switching the active collector MUST NOT delete VictoriaMetrics persistent storage or historical data.
- **FR-008**: Grafana MUST retain access to installed metrics datasources and select the active collector's datasource by default.
- **FR-009**: The module MUST report a clear validation error for unsupported selector values or a selected backend that is not installed.
- **FR-010**: The module README and examples MUST document installation of both backends, Prometheus-first validation, and switching to VictoriaMetrics collection.
- **FR-011**: Existing Prometheus-only configurations MUST continue to work without requiring a new selector value.
- **FR-012**: VictoriaMetrics collector mode MUST render operational resource defaults for the operator-managed VMAgent and a higher remote-write queue count, while allowing explicit VMAgent spec overrides to replace non-selector-owned defaults.
- **FR-013**: The VictoriaMetrics cluster MUST render resource defaults with ingestion headroom for vminsert and vmstorage, apply `victoria_metrics.extra_configs` to non-endpoint settings, and apply a final protected vminsert/vmselect service identity and port contract that remains consistent with derived remote-write and query URLs.
- **FR-014**: The module MUST deploy kube-state-metrics through an independent Helm release whose lifecycle does not depend on `prometheus.enabled` or `metrics_collector`.
- **FR-015**: The Prometheus Helm release MUST disable its bundled kube-state-metrics dependency in all collector modes.
- **FR-016**: Prometheus mode MUST enable one standalone kube-state-metrics `ServiceMonitor` labeled for the configured Prometheus release, using endpoint port `http` and `honorLabels = true`.
- **FR-017**: VictoriaMetrics mode MUST disable that Prometheus `ServiceMonitor` and render one native `VMServiceScrape` for the derived kube-state-metrics Service.
- **FR-018**: VictoriaMetrics mode MUST NOT render the former static kube-state-metrics vmagent job, preventing duplication with the native `VMServiceScrape`.
- **FR-019**: The default independent Service DNS MUST remain `prometheus-kube-state-metrics.monitoring.svc.cluster.local:8080`, while custom release names and namespaces remain derivable.
- **FR-020**: The generated kube-state-metrics `VMServiceScrape` MUST set `max_scrape_size = "32MiB"` without raising VMAgent's global scrape-size limit.
- **FR-021**: The module MUST install the official `victoria-metrics-operator` chart when VictoriaMetrics is installed, with an explicit tested chart version and configurable non-critical chart overrides, ordered after Prometheus monitor CRD installation and independent kube-state-metrics namespace creation.
- **FR-022**: Prometheus `PodMonitor` and `ServiceMonitor` conversion MUST remain enabled in the VictoriaMetrics Operator.
- **FR-023**: Converted scrape objects MUST receive owner references so deleting a source monitor removes its converted object.
- **FR-024**: An operator-managed `VMAgent` custom resource MUST exist only when `metrics_collector = "victoria_metrics"`.
- **FR-025**: The VMAgent MUST select converted scrape objects across namespaces and remote-write to the existing derived VictoriaMetrics vminsert URL.
- **FR-026**: The standalone `victoria-metrics-agent` Helm release MUST be removed from the selected implementation.
- **FR-027**: Monitor conversion MUST preserve endpoint authorization type and Secret key selectors without exposing Secret values in Terraform state, Helm values, examples, or documentation.
- **FR-028**: An application with a valid Prometheus monitor MUST NOT require a duplicate manual VictoriaMetrics scrape job.
- **FR-029**: When both backends are installed and Prometheus is selected, the operator MAY synchronize converted objects but MUST NOT create an active VMAgent scraper.
- **FR-030**: Existing `victoria_metrics.agent.extra_scrape_configs` MUST remain available for exceptional targets without monitor CRs and MUST be represented in operator-managed VMAgent configuration.
- **FR-031**: Selector-owned VMAgent values, including activation, selectors, remote-write destination, and replica count, MUST remain authoritative over raw overrides.
- **FR-032**: The AWS wrapper MUST mirror and forward the revised VictoriaMetrics Operator and VMAgent input contract without duplicating base-module resources.
- **FR-033**: A caller-provided VMAgent extra scrape job named `kube-state-metrics` MUST suppress the generated native `VMServiceScrape` during migration; the caller-owned job remains responsible for its own scrape-size limit.
- **FR-034**: Operator-based monitor conversion MUST require both Prometheus and VictoriaMetrics installations until Prometheus monitoring CRDs have an independently managed lifecycle.
- **FR-035**: `operator.extra_configs` MUST be applied before selector-owned values and MUST NOT override conversion enablement, converter ownership, the chart's top-level `watchNamespaces = []`, filtered namespace/converter env plus empty `envFrom`, `extraArgs["controller.disableReconcileFor"] = []`, required RBAC/CRDs, cleanup safety, or generated `extraObjects`; unrelated explicit Operator env and extra arguments MUST remain usable.
- **FR-036**: `agent.extra_configs` MUST NOT override VMAgent activation, `selectAllByDefault`, Pod/Service scrape or namespace selectors, remote-write destination, name, replica count, or inline scrape configuration.
- **FR-037**: The VMAgent name MUST be a valid Kubernetes resource name and its replica count MUST be a positive integer.
- **FR-038**: The generated kube-state-metrics `VMServiceScrape` MUST use a distinct `<Service fullname>-victoria-metrics` object name, the resolved exporter namespace, derived Service selector labels, endpoint port `http`, `honorLabels = true`, and endpoint-level `max_scrape_size = "32MiB"` so it cannot collide with the Operator-converted source monitor during handoff.
- **FR-039**: Exactly one scraper MUST be rendered in converged state; documentation MUST disclose that a selector apply across independent Helm releases may have a bounded overlap or collection gap.
- **FR-040**: Rollout documentation MUST require Prometheus queue-drain checks before switching and VMAgent pending-data/error checks before rollback when agent queue storage is ephemeral.
- **FR-041**: Operator runtime Secret resolution MUST be documented, including its need to read source Secrets, the pinned chart ClusterRole's broader cluster-wide wildcard verbs on `secrets` and `secrets/finalizers`, and the generated configuration Secret containing resolved credentials.
- **FR-042**: The Operator Helm release MUST protect `crds.enabled = true`, `crds.plain = true`, and `crds.upgrade.enabled = true` so a fresh-cluster apply installs CRDs before generated custom resources are REST-mapped and later chart upgrades can update those plain CRDs.

### Key Entities

- **Collector Selection**: The operator-selected active metrics scraper, either Prometheus or VictoriaMetrics.
- **Backend Installation**: The independently configurable Prometheus or VictoriaMetrics Helm release and its persistent storage.
- **Metrics Datasource**: The Grafana query endpoint associated with an installed metrics backend.
- **Collection Transition**: A change of active scraper that preserves stored history and may produce a bounded no-data interval.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A valid configuration with both releases enabled produces exactly one active scraper in converged Terraform-rendered output.
- **SC-002**: A Prometheus-first validation configuration can deliver a generated sample to both Prometheus and VictoriaMetrics without duplicate scraping configuration.
- **SC-003**: A VictoriaMetrics-mode configuration renders an active collector write path and disables Prometheus scraping within the same Terraform plan.
- **SC-004**: Switching the collector selection leaves existing VictoriaMetrics persistent-storage resources unchanged.
- **SC-005**: All focused Terraform tests for selector validation, Prometheus mode, VictoriaMetrics mode, and both-installed rollout pass before release.
- **SC-006**: Focused Terraform tests verify the rendered vminsert/vmstorage/VMAgent resources, 16 remote-write queues, nested Prometheus overrides, protected monitor CRDs, stable vminsert/vmselect endpoints, and partial caller overrides without applying a Helm release.
- **SC-007**: A dual-backend VictoriaMetrics-mode plan still reports the independent kube-state-metrics release as installed while the Prometheus server is disabled.
- **SC-008**: Focused tests show the Prometheus and VictoriaMetrics modes render mutually exclusive kube-state-metrics scrape paths.
- **SC-009**: The first migration preserves the existing Service DNS and orders removal of Prometheus-owned exporter resources before creation by the standalone Helm release.
- **SC-010**: Focused tests prove that the generated kube-state-metrics `VMServiceScrape` renders a 32 MiB per-target scrape limit, the former generated static job is absent, and a caller-owned transition job suppresses the native object.
- **SC-011**: Helm-rendered output contains one operator-managed VMAgent in VictoriaMetrics mode and no standalone vmagent Helm release.
- **SC-012**: Live evidence shows an authorization-enabled source `PodMonitor`, its converted `VMPodScrape`, a healthy VMAgent target, and the expected application metric in VictoriaMetrics.
- **SC-013**: Switching back to Prometheus removes the VMAgent resource, restores Prometheus collection, and leaves VictoriaMetrics vmstorage/PVC identities unchanged.
- **SC-014**: Focused AWS wrapper tests prove the revised nested operator and agent configuration is accepted and forwarded unchanged.
- **SC-015**: A VictoriaMetrics-selected plan with `prometheus.enabled = false` fails with a clear message that Prometheus monitoring CRDs do not yet have independent ownership.
- **SC-016**: Tests prove protected Operator/VMAgent values win over conflicting raw overrides, including controller-disable/env/envFrom attempts and Pod/Service selector narrowing; zero, negative, and fractional VMAgent replica counts plus malformed DNS names such as `a..b` and `a.-b` are rejected.
- **SC-017**: The rendered native kube-state-metrics object contains the exact namespace selector, Service selector, endpoint port, honor-label setting, and endpoint-level 32 MiB limit.
- **SC-018**: A focused regression test proves caller overrides cannot disable the Operator chart's plain CRD bootstrap or CRD upgrade hook, and a pinned chart render places required CRDs in Helm's CRD payload while retaining generated custom resources.

## Assumptions

- Operators provide the Kubernetes and Helm provider configuration required by the existing module.
- `prometheus.enabled` and `victoria_metrics.enabled` continue to control whether each backend release is installed; the new selector controls which installed backend actively scrapes.
- VictoriaMetrics Cluster remains the storage/query backend for this feature; migrating to the all-in-one VictoriaMetrics K8s Stack is out of scope.
- VictoriaMetrics Operator chart `0.67.2` and its operator-managed `VMAgent` CR are the default VictoriaMetrics collector implementation for this feature.
- Prometheus monitoring CRDs remain supplied by the installed kube-prometheus-stack release, allowing application charts to keep creating `PodMonitor` and `ServiceMonitor` objects.
- The operator watches all relevant namespaces and the VMAgent uses `selectAllByDefault = true`; tighter tenant selectors are a separate hardening change.
- Secret references used by monitor endpoints are in the same namespace as their source monitor and are readable by VictoriaMetrics Operator; resolved values are stored in the generated VMAgent configuration Secret at runtime. The pinned chart-owned ClusterRole grants wildcard verbs on Secrets, so the Operator service account plus source and generated Secrets require restricted access and auditing.
- Existing retention periods and persistent-volume settings remain unchanged.
- VMAgent persistent-queue storage remains controlled by its CR spec or explicit `victoria_metrics.agent.extra_configs`; this change does not enable a PVC.
- The standalone kube-state-metrics chart initially stays at `6.1.0`, matching the dependency bundled by kube-prometheus-stack `75.8.0`.
- Removing the entire kube-prometheus-stack release and independently replacing all exporters and rules is outside this migration; the selected rollout keeps both backends installed.
- The exactly-one-scraper invariant applies after Terraform/Helm convergence; a bounded transition overlap or gap is accepted and documented because the two Helm releases cannot switch atomically.
