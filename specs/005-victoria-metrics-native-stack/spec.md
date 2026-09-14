# Feature Specification: VictoriaMetrics Native Stack

**Feature Branch**: `005-victoria-metrics-native-stack` (branch creation skipped by user request)  
**Created**: 2026-08-31  
**Revised**: 2026-09-14
**Status**: Implemented
**Input**: Replace the Prometheus stack completely with VictoriaMetrics when selected, while keeping shared metric exporters independent and preserving a safe one-collector migration mode.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run VictoriaMetrics Without Prometheus (Priority: P1)

As a platform operator, I can select VictoriaMetrics and disable Prometheus so
the metrics platform runs without the Prometheus server, Prometheus Operator,
or Prometheus monitor definitions while retaining Kubernetes workload, node,
and cluster-state metrics.

**Why this priority**: This is the primary migration outcome. Without it,
VictoriaMetrics remains dependent on the stack it is intended to replace.

**Independent Test**: Plan and render a configuration with VictoriaMetrics
selected and enabled and Prometheus disabled. The result contains the selected
VictoriaMetrics collector, its own discovery definitions, shared exporters,
and no Prometheus monitor definitions.

**Acceptance Scenarios**:

1. **Given** VictoriaMetrics is selected and enabled, **When** Prometheus is disabled, **Then** the configuration is valid and installs no Prometheus stack.
2. **Given** a clean cluster with no Prometheus Operator definitions, **When** the VictoriaMetrics-only configuration is applied, **Then** all selected VictoriaMetrics resources can be created without an unsupported-resource error.
3. **Given** VictoriaMetrics-only mode is active, **When** the collector discovers Kubernetes targets, **Then** cluster state, node, kubelet, cAdvisor, filesystem, volume, network, and pod resource metrics have an active collection path.
4. **Given** VictoriaMetrics-only mode, **When** generated resources are inspected, **Then** none use the Prometheus Operator API group.
5. **Given** VictoriaMetrics-only mode, **When** kube-prometheus-stack is absent, **Then** enabled Kubernetes components retain native Services and VictoriaMetrics scrape definitions without duplicate paths.

---

### User Story 2 - Keep Shared Exporters Across Collector Changes (Priority: P2)

As a platform operator, I can switch the selected collector without deleting
kube-state-metrics or node-exporter because these exporters are installed and
managed independently from either metrics backend.

**Why this priority**: Cluster-state, filesystem, and host metrics must not
disappear when Prometheus is removed.

**Independent Test**: Compare Prometheus-only and VictoriaMetrics-only plans.
Both plans retain the same enabled shared exporters, but each exposes exactly
one discovery definition compatible with the selected collector.

**Acceptance Scenarios**:

1. **Given** Prometheus is selected, **When** shared exporters are enabled, **Then** Prometheus-compatible discovery is enabled and VictoriaMetrics-native discovery is absent.
2. **Given** VictoriaMetrics is selected, **When** shared exporters are enabled, **Then** VictoriaMetrics-native discovery is enabled and Prometheus-compatible discovery is absent.
3. **Given** the selected collector changes, **When** the next plan is reviewed, **Then** shared exporter lifecycle is preserved and no duplicate exporter instance or duplicate scrape path is introduced.
4. **Given** an exporter is explicitly disabled, **When** either collector is selected, **Then** neither its workload nor a generated discovery definition is present.

---

### User Story 3 - Migrate With Both Backends Installed (Priority: P3)

As a platform operator, I can keep both metrics backends installed during a
controlled migration while only the selected collector actively scrapes and
only the selected datasource is the Grafana default.

**Why this priority**: Existing application monitors and rollback requirements
make a one-step replacement too risky.

**Independent Test**: Plan configurations with both backends installed and
each selector value. In every case exactly one collector is active and exactly
one installed metrics datasource is default.

**Acceptance Scenarios**:

1. **Given** both backends are installed and Prometheus is selected, **When** the plan is applied, **Then** Prometheus scrapes and the VictoriaMetrics collector is inactive.
2. **Given** both backends are installed and VictoriaMetrics is selected, **When** the plan is applied, **Then** VictoriaMetrics scrapes, the Prometheus server is inactive, and compatibility with existing Prometheus application monitors remains available.
3. **Given** VictoriaMetrics has historical samples, **When** only the selected collector changes, **Then** VictoriaMetrics storage is not replaced or deleted.
4. **Given** a migration rollback, **When** Prometheus is re-enabled and selected, **Then** the Prometheus collection path can resume without deleting VictoriaMetrics data.
5. **Given** both backends are installed and VictoriaMetrics is selected, **When** kubelet and cAdvisor discovery is rendered, **Then** the kube-prometheus-stack kubelet ServiceMonitor is disabled and the native VMNodeScrapes are the only module-managed collection paths for those endpoints.

---

### User Story 4 - Preserve Module-Owned Metrics Integrations (Priority: P4)

As a platform operator, I receive a valid selected datasource and write target
for module-owned components without having to reference a disabled backend.

**Why this priority**: A standalone collector is incomplete if Grafana or
module-owned telemetry still points to Prometheus.

**Independent Test**: Plan a VictoriaMetrics-only configuration with Grafana,
Tempo, and Loki enabled. The default metrics datasource and omitted remote
write destinations resolve to VictoriaMetrics, and no module-owned Prometheus
monitor is produced.

**Acceptance Scenarios**:

1. **Given** only VictoriaMetrics is installed, **When** Grafana datasources are resolved, **Then** VictoriaMetrics is the only metrics datasource and is default.
2. **Given** Tempo metrics generation is enabled without an explicit destination, **When** VictoriaMetrics is selected, **Then** generated metrics are written to the selected VictoriaMetrics ingestion endpoint.
3. **Given** a caller supplies an explicit Tempo destination, **When** either collector is selected, **Then** the explicit destination is preserved.
4. **Given** a module-owned component normally creates a Prometheus monitor, **When** VictoriaMetrics-only mode is selected, **Then** that monitor is suppressed and any expected self-metrics use compatible native discovery.

### Edge Cases

- The selected collector backend is disabled while the other backend is installed.
- Both backends are disabled.
- Both backends are installed and the selector changes without changing storage configuration.
- A shared exporter is disabled while its generated discovery definition would otherwise be enabled.
- Raw backend overrides attempt to re-enable a bundled exporter or a second active scraper.
- Raw collector overrides attempt to exclude module-owned discovery definitions.
- Old Prometheus Operator definitions remain in a cluster after Prometheus is disabled.
- Application-owned Prometheus monitors have not yet been migrated to native VictoriaMetrics definitions.
- A caller has additional Prometheus scrape jobs with authentication or backend-specific discovery.
- A caller supplies a VictoriaMetrics inline job for a module-owned KSM,
  node-exporter, Tempo, or Loki endpoint and must suppress only the matching
  generated `VMServiceScrape` without uninstalling that workload.
- Tempo has a caller-owned remote-write destination that differs from both module-managed backends.
- An interrupted or targeted in-place upgrade leaves same-name
  kube-state-metrics objects annotated for the old Helm release.
- Selecting VictoriaMetrics removes the Prometheus custom resource and
  StatefulSet while retained PVCs are not visible as child-resource actions in
  Terraform's Helm diff.
- VictoriaMetrics is installed only as a storage/query backend while its
  Operator gate is omitted or explicitly disabled; no Operator, VictoriaMetrics
  CRD release, custom-resource release, or associated cluster-wide RBAC may be
  created.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST continue to support `prometheus` and `victoria_metrics` as the only collector selections.
- **FR-002**: The module MUST reject a configuration when the selected backend is not installed.
- **FR-003**: The module MUST accept VictoriaMetrics selection with VictoriaMetrics enabled and Prometheus disabled.
- **FR-004**: VictoriaMetrics-only mode MUST install no Prometheus stack component.
- **FR-005**: VictoriaMetrics-only mode MUST require no Prometheus Operator custom-resource definition.
- **FR-006**: Every custom resource generated in VictoriaMetrics-only mode MUST use the VictoriaMetrics Operator API group.
- **FR-007**: The VictoriaMetrics Operator MUST supply the definitions required by all generated VictoriaMetrics resources on a clean cluster.
- **FR-008**: Prometheus-object conversion MUST be disabled when Prometheus is not installed.
- **FR-009**: Prometheus-object conversion MUST remain available during a dual-backend VictoriaMetrics migration while Prometheus is installed.
- **FR-010**: Exactly one collector MUST actively scrape in every valid configuration.
- **FR-011**: The active VictoriaMetrics collector MUST write to the selected VictoriaMetrics storage backend.
- **FR-012**: kube-state-metrics lifecycle MUST remain independent of both backend installation flags and the collector selector.
- **FR-013**: node-exporter lifecycle MUST remain independent of both backend installation flags and the collector selector.
- **FR-014**: The Prometheus stack MUST NOT install bundled copies of shared exporters managed independently by this module.
- **FR-015**: Each enabled shared exporter MUST have exactly one generated discovery path for the selected collector.
- **FR-016**: Prometheus mode MUST use Prometheus-compatible discovery for shared exporters.
- **FR-017**: VictoriaMetrics mode MUST use native VictoriaMetrics discovery for shared exporters.
- **FR-018**: VictoriaMetrics mode MUST provide native collection paths for kubelet, cAdvisor, and configured resource metrics.
- **FR-019**: Native node collection MUST authenticate through workload identity available to the collector and MUST NOT embed a credential value in configuration or state.
- **FR-020**: Native Kubernetes collection MUST preserve metric names and identifying labels required by existing workload, volume, network, and node dashboards.
- **FR-021**: Explicitly disabling a shared exporter MUST suppress both its workload and all module-generated discovery definitions for it.
- **FR-022**: Selector-owned settings MUST take precedence over raw backend and collector overrides for scraper activation, bundled exporters, required definitions, discovery selectors, and managed write destinations.
- **FR-023**: VM-only mode MUST suppress Prometheus monitor resources from module-owned components.
- **FR-024**: Module-owned component self-metrics that are expected by the current module contract MUST retain a native VictoriaMetrics discovery path in VM-only mode.
- **FR-025**: An omitted Tempo metrics destination MUST resolve to the ingestion endpoint of the selected collector.
- **FR-026**: An explicitly configured Tempo metrics destination MUST remain unchanged.
- **FR-027**: Grafana MUST provision datasources only for installed backends.
- **FR-028**: Grafana MUST mark exactly one installed metrics datasource as default, matching the collector selector.
- **FR-029**: Switching only the collector selector MUST NOT delete or replace VictoriaMetrics storage.
- **FR-030**: The module MUST NOT automatically delete old Prometheus Operator definitions or the custom resources stored under them.
- **FR-031**: Caller-owned Prometheus additional scrape jobs MUST NOT be copied implicitly to VictoriaMetrics configuration.
- **FR-032**: Caller-owned VictoriaMetrics scrape jobs MUST remain supported without storing secret values in module-generated documentation, outputs, or tests.
- **FR-033**: Module outputs MUST expose non-sensitive resolved status for selected collector, installed backends, converter state, shared exporters, native discovery, and default datasource.
- **FR-034**: Existing Prometheus-only configurations using defaults MUST remain valid after the feature is introduced.
- **FR-035**: The feature MUST NOT require changes in an application chart, wrapper module, or environment file to validate the base module contract.
- **FR-036**: VictoriaMetrics-only mode MUST provide native discovery for enabled CoreDNS, kube-proxy, kube-controller-manager, kube-scheduler, and etcd metrics without requiring kube-prometheus-stack.
- **FR-037**: Kubernetes API server native discovery MUST be supported but disabled by default to match the existing Prometheus module default.
- **FR-038**: VM-only mode MUST create the Services required to replace kube-prometheus-stack-owned component discovery, while API server discovery MUST reuse the existing Kubernetes Service.
- **FR-039**: Native Kubernetes component scrape endpoints MUST preserve the existing job labels, standard ports, HTTP/HTTPS behavior, CA file, and metric relabeling needed by current dashboards; the service-account token MUST be sent only to authenticated HTTPS endpoints with certificate verification enabled.
- **FR-040**: Native Kubernetes component Services and VMServiceScrapes MUST be generated only in standalone VictoriaMetrics mode; dual-backend VictoriaMetrics mode MUST continue to use converted kube-prometheus-stack ServiceMonitors to avoid duplicate scraping.
- **FR-041**: Callers MUST be able to disable each native Kubernetes component scrape and override the component and API server namespaces through one grouped optional VictoriaMetrics agent input.
- **FR-042**: The kube-prometheus-stack kubelet ServiceMonitor MUST be selector-owned: enabled only when Prometheus is the selected collector and disabled when VictoriaMetrics is selected, including when raw Prometheus chart overrides attempt to re-enable it.
- **FR-043**: Migration documentation MUST disclose the kube-state-metrics Helm ownership transfer, node-exporter fullname replacement, Prometheus custom-resource and StatefulSet removal, Prometheus PVC verification, complete non-targeted apply requirement, and bounded stale-ownership recovery.
- **FR-044**: `victoria_metrics.operator.enabled` MUST default to `false` and gate both the VictoriaMetrics Operator Helm release and its dependent custom-resource release, while leaving the VictoriaMetrics cluster available as a storage/query backend.
- **FR-045**: Selecting `metrics_collector = "victoria_metrics"` MUST require both `victoria_metrics.enabled = true` and `victoria_metrics.operator.enabled = true`; Prometheus collection MAY remote-write to VictoriaMetrics while the Operator is disabled.
- **FR-046**: Operator, converter, VMAgent, generated scrape-object, and installation-status outputs MUST resolve to absent, false, or empty values when the Operator gate is disabled.
- **FR-047**: Native node metric keep filters MUST route known metric families only to kubelet endpoints that expose them: kubelet, cAdvisor, or resource metrics.
- **FR-048**: kube-state-metrics and scheduler-only metric families MUST NOT be included in module-default VMNodeScrape filters; caller-supplied unknown patterns MUST remain backward-compatible by applying to every enabled node endpoint.
- **FR-049**: Native kubelet, cAdvisor, and resource VMNodeScrapes that disable target certificate validation MUST omit `caFile`; verified API-server and Kubernetes component scrape TLS configuration MUST remain unchanged.
- **FR-050**: The optional grouped `victoria_metrics.agent.managed_service_scrapes` input MUST expose default-enabled switches for kube-state-metrics, node-exporter, Tempo, and Loki; disabling one switch MUST suppress only its module-generated `VMServiceScrape`, preserve the underlying workload and caller-owned inline jobs, and leave all other generated scrape paths unchanged. The existing exact `kube-state-metrics` transition-job suppression MUST remain backward-compatible.
- **FR-051**: The VictoriaMetrics child module MUST default the `victoria-metrics-cluster` release to the same published chart version as the root module (`0.31.0`).

### Key Entities

- **Metrics Backend**: An installed storage and query system; either Prometheus or VictoriaMetrics.
- **Collector Selection**: The operator choice that determines the sole active scraper and default metrics datasource.
- **Shared Exporter**: A metrics-producing workload whose lifecycle is independent of a backend, including kube-state-metrics and node-exporter.
- **Discovery Definition**: A collector-compatible declaration that identifies and configures scrape targets.
- **Compatibility Mode**: A dual-backend state that permits existing Prometheus application monitors to feed the selected VictoriaMetrics collector during migration.
- **Module-Owned Integration**: Grafana, Tempo, Loki, or another component whose metrics endpoint, monitor, or write destination is configured by this module.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A VictoriaMetrics-only configuration completes validation with zero installed Prometheus stack releases and zero generated Prometheus Operator custom resources.
- **SC-002**: A clean-cluster render contains all definitions required by every generated VictoriaMetrics resource, with zero unsupported-resource mapping failures.
- **SC-003**: Prometheus-only, VictoriaMetrics-only, and both dual-backend selector configurations each resolve exactly one active collector and exactly one default metrics datasource.
- **SC-004**: In both single-backend modes, 100% of enabled shared exporters have exactly one discovery path and zero duplicate module-managed scrape paths.
- **SC-005**: VictoriaMetrics-only mode provides active configuration paths for all six required metric categories: cluster state, container resources, network, volumes, filesystems, and node health.
- **SC-006**: A selector-only migration plan contains zero replacement or deletion actions for VictoriaMetrics persistent storage.
- **SC-007**: Existing Prometheus-only default configurations continue to pass all pre-existing focused module tests.
- **SC-008**: Raw override tests demonstrate that 100% of selector-owned activation, definition, discovery, and destination settings retain the module-resolved value.
- **SC-009**: No test fixture, output, documentation example, or generated non-secret scrape configuration contains a credential value.
- **SC-010**: The migration quickstart identifies a verifiable application-migration gate before Prometheus can be safely disabled and a rollback path that preserves VictoriaMetrics history.
- **SC-011**: A VM-only render contains three safe enabled-by-default Kubernetes component Service/VMServiceScrape configurations, requires explicit TLS settings before controller-manager or scheduler can be enabled, contains no enabled-by-default API server scrape, and contains zero Prometheus Operator resources; rendered status does not claim runtime target health.
- **SC-012**: A dual-backend VictoriaMetrics render contains zero module-generated native Kubernetes component Service/VMServiceScrape pairs, preventing duplicate collection with converted ServiceMonitors.
- **SC-013**: Each dual-backend selector render contains exactly one module-managed kubelet/cAdvisor discovery path: the kube-prometheus-stack ServiceMonitor for Prometheus selection or native VMNodeScrapes for VictoriaMetrics selection.
- **SC-014**: The root README and migration quickstart identify the exact old/new exporter identities, require before/after Prometheus PVC inventories and complete applies, and limit ownership recovery to a verified exact stale object.
- **SC-015**: A focused plan with Prometheus selected, VictoriaMetrics enabled, and the Operator omitted creates only the VictoriaMetrics cluster and reports no Operator, converter, VMAgent, or generated VM scrape objects.
- **SC-016**: Focused tests reject VictoriaMetrics selection when its Operator is disabled and prove that explicitly enabling the Operator creates both Operator-related Helm releases.
- **SC-017**: Focused tests prove distinct kubelet, cAdvisor, and resource keep filters, the correct `pod_memory_working_set_bytes` resource metric, exclusion of known KSM/scheduler-only patterns, and preservation of custom caller patterns.
- **SC-018**: Focused tests prove every native node VMNodeScrape retains `insecureSkipVerify = true` without a redundant `caFile`, while verified component and API-server scrapes retain their CA configuration.
- **SC-019**: Focused root tests prove all four managed service-scrape switches default to enabled and can independently suppress their generated `VMServiceScrape` objects while exporter/component workloads and caller-owned inline jobs remain configured.
- **SC-020**: A focused direct-child plan resolves the default `victoria-metrics-cluster` Helm release version to `0.31.0`.

## Assumptions

- The existing VictoriaMetrics Cluster storage layout and service identities remain stable.
- The existing Grafana-managed alerting resources remain the module's alerting mechanism; replacing Prometheus Alertmanager and chart-provided alert rules is outside scope.
- Applications will create native VictoriaMetrics discovery and rule definitions before Prometheus compatibility is removed.
- Callers will move backend-specific additional scrape jobs explicitly rather than relying on automatic translation.
- Old Prometheus Operator definitions may remain installed temporarily after migration, but VM-only module operation does not depend on them.
- Kubernetes nodes expose kubelet, cAdvisor, and resource endpoints to the selected collector using cluster service-account authentication.
- Shared exporters expose Prometheus-format metrics consumable by either supported collector.
- The AWS wrapper and environment configuration will adopt the revised base-module input contract separately.
