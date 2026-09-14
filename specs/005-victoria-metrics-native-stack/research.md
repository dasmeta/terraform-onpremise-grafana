# Research: VictoriaMetrics Native Stack

## Decision 1: Install VM CRDs before VM custom resources

**Decision**: Keep the pinned `victoria-metrics-operator` chart as the owner of
the official VictoriaMetrics CRDs, but stop rendering `VMAgent`,
`VMServiceScrape`, and `VMNodeScrape` through that release's `extraObjects`.
Render those objects through a small module-local Helm chart in a second
`helm_release` that depends on the Operator release.

**Rationale**: A fresh cluster can reject custom resources while Helm is still
building a release that also introduces their CRDs. A second release gives
Terraform and Helm an explicit ordering boundary: the Operator release first
registers the official CRDs, then the resources release creates instances of
those kinds. The module does not fork or copy CRD schemas.

**Alternatives considered**:

- Keep all objects in Operator `extraObjects`: rejected because it reproduced
  `no matches for kind` mapping errors on a clean cluster.
- Install `prometheus-operator-crds`: rejected because VM-only resources do not
  use the Prometheus Operator API group.
- Add the Kubernetes provider and `kubernetes_manifest`: rejected because it
  expands the root provider contract and still requires careful CRD planning.
- Maintain private VM CRD YAML: rejected because schemas would drift from the
  pinned Operator version.

**Primary source**: [VictoriaMetrics Operator Helm chart](https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-operator)

## Decision 2: Use native VM discovery in standalone mode

**Decision**: VM-only mode uses `VMServiceScrape`, `VMPodScrape` supplied by
applications, and module-owned `VMNodeScrape` objects. It creates no
`monitoring.coreos.com` resource.

**Rationale**: The VictoriaMetrics Operator owns these CRDs and VMAgent can
select them directly. This removes the dependency on Prometheus Operator CRDs.

**Alternatives considered**:

- Keep Prometheus monitor CRDs without Prometheus server: rejected because it
  does not deliver a fully independent VictoriaMetrics stack.
- Convert every scrape to inline VMAgent YAML: rejected because native objects
  preserve Kubernetes discovery, namespace selection, authorization selectors,
  and resource ownership more safely.

**Primary sources**:

- [VictoriaMetrics Operator resources](https://docs.victoriametrics.com/operator/resources/)
- [VMNodeScrape](https://docs.victoriametrics.com/operator/resources/vmnodescrape/)

## Decision 3: Make Prometheus conversion conditional

**Decision**: Disable the Prometheus converter when Prometheus is not
installed. Keep it enabled when both backends are installed, including while
VictoriaMetrics is selected, so existing application-owned `PodMonitor` and
`ServiceMonitor` objects can be migrated gradually.

**Rationale**: VM-only must not require Prometheus CRDs. During a dual-backend
migration, converter compatibility is useful until applications own native VM
scrape resources.

**Alternatives considered**:

- Always enable conversion: rejected because it leaves a VM-only dependency on
  Prometheus APIs.
- Always disable conversion: rejected because it creates an avoidable breaking
  migration for authenticated application monitors.

**Primary source**: [Prometheus integration in VictoriaMetrics Operator](https://docs.victoriametrics.com/operator/integrations/prometheus/)

## Decision 4: Split both shared exporters from the Prometheus stack

**Decision**: Keep the existing independent `kube-state-metrics` release and
add an independent `prometheus-node-exporter` release pinned to chart `4.47.1`,
the version bundled by the existing `kube-prometheus-stack` pin. Disable both
bundled exporters in the Prometheus chart.

**Rationale**: Exporters produce Prometheus-format metrics but are not tied to
a storage backend. Independent lifecycle prevents their deletion when the
Prometheus stack is removed. Pinning the current bundled chart version limits
migration drift.

**Alternatives considered**:

- Keep node-exporter bundled: rejected because VM-only would lose node and
  filesystem metrics.
- Install a second exporter only in VM mode: rejected because switching modes
  would replace ownership and risks duplicate scraping.
- Use annotation scraping: rejected because it is less explicit and can create
  a second scrape path.

**Primary source**: [prometheus-node-exporter Helm chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-node-exporter)

## Decision 5: Preserve Kubernetes metric coverage with VMNodeScrape

**Decision**: In VictoriaMetrics mode, generate native node scrapes for:

- kubelet `/metrics`;
- cAdvisor `/metrics/cadvisor`;
- `/metrics/resource` only when explicitly enabled.

The objects use HTTPS, the collector's mounted service-account token and CA,
node-address relabeling, and the same metric-name allowlist used by the current
Prometheus kubelet monitor.

**Rationale**: cAdvisor supplies container CPU, memory, network, and filesystem
series; kubelet supplies volume and health metrics; node-exporter supplies host
and filesystem metrics. Runtime service-account authentication avoids putting
tokens in Terraform configuration or state.

**Alternatives considered**:

- Scrape kubelet with static node IPs: rejected because it duplicates native
  Kubernetes node discovery and is brittle during node replacement.
- Enable the resource endpoint by default: rejected because the existing
  Prometheus contract does not enable it and the rollout should avoid adding
  duplicate resource series unexpectedly.

## Decision 6: Make module-owned monitors collector-aware

**Decision**: Prometheus mode retains module-owned `ServiceMonitor` behavior.
VictoriaMetrics mode suppresses those monitors and creates native
`VMServiceScrape` resources for enabled Tempo and Loki self-monitoring paths.
Grafana's default-disabled ServiceMonitor remains disabled in VM-only mode.

**Rationale**: A VM-only render must not include Prometheus custom resources,
while currently expected component self-metrics must remain collectible.

**Alternatives considered**:

- Depend on converter for module-owned monitors: rejected in VM-only mode
  because the converter is intentionally disabled.
- Disable all component self-monitoring: rejected because it silently removes
  existing observable behavior.

**Primary sources**:

- [Tempo Helm chart](https://github.com/grafana/helm-charts/tree/main/charts/tempo)
- [Loki Helm chart](https://github.com/grafana/loki/tree/main/production/helm/loki)

## Decision 7: Resolve omitted Tempo remote write from the selector

**Decision**: Change the root Tempo `metrics_generator.remote_url` default to
`null`. When null, derive the endpoint from the selected backend; preserve any
explicit non-null URL.

**Rationale**: A hard-coded Prometheus URL makes VM-only mode invalid. Nullable
input distinguishes an omitted value from a caller-owned destination.

**Alternatives considered**:

- Always overwrite with the selected backend: rejected because callers may
  intentionally remote-write to an external system.
- Keep the current Prometheus default: rejected because it points to a disabled
  service in VM-only mode.

## Decision 8: Enforce selector-owned values after raw overrides

**Decision**: Apply final protected Helm values after `extra_configs` for
collector activation, bundled exporters, CRD management, monitor generation,
native discovery selection, and managed write endpoints. Preserve unrelated
caller settings and merge partial resource/extra-argument overrides.

**Rationale**: `metrics_collector` is an invariant, not a hint. Raw values must
not produce two active collectors or silently omit required VM discovery.

**Alternatives considered**:

- Document unsafe combinations only: rejected because an accepted Terraform
  plan could violate the public module contract.
- Block all raw values: rejected because callers still need scheduling,
  images, tolerations, resources, and chart-specific settings.

## Decision 9: Do not auto-translate or delete caller-owned resources

**Decision**: Do not translate Prometheus additional scrape jobs, application
monitors, or rules. Do not delete old Prometheus CRDs. Document an explicit
application migration gate and manual cleanup boundary.

**Rationale**: Scrape jobs can contain backend-specific service discovery and
authentication. Deleting a CRD can delete every custom resource of that kind.
Both actions require application-owner verification outside this module.

## Decision 10: Replace kube-prometheus-stack component discovery in VM-only mode

**Decision**: Generate native Kubernetes component discovery only when
VictoriaMetrics is selected and Prometheus is not installed. CoreDNS,
kube-proxy, kube-controller-manager, kube-scheduler, and etcd receive dedicated
Services and `VMServiceScrape` resources. Kubernetes API server discovery is
optional and selects the existing `default/kubernetes` Service.

The native definitions mirror kube-prometheus-stack `75.8.0` ports, selectors,
job labels, and the module's CoreDNS/kube-proxy `go_*` metric drop. They tighten
the credential transport contract: service-account credentials are omitted
from plain HTTP targets and authenticated HTTPS targets verify the mounted CA.
Component and API server namespaces are grouped with the per-component switches
under `victoria_metrics.agent.kubernetes_component_scrapes`.
The same group carries controller-manager and scheduler CA/SAN settings. The
default verifies TLS; `insecure_skip_verify` is available only as an explicit
compatibility choice for clusters that cannot expose a verifiable certificate.

The parity oracle from kube-prometheus-stack `75.8.0` is:

| Input key | Service pod selector | Job label | Port | Path | Transport | Metric relabeling |
|---|---|---|---:|---|---|---|
| `core_dns` | `k8s-app=kube-dns` | `coredns` | `9153` | `/metrics` | HTTP, no credentials | drop `^go_.*` |
| `kube_proxy` | `k8s-app=kube-proxy` | `kube-proxy` | `10249` | `/metrics` | HTTP, no credentials | drop `^go_.*` |
| `controller_manager` | `component=kube-controller-manager` | `kube-controller-manager` | `10257` | `/metrics` | verified HTTPS + token/CA files + server name `kubernetes` | none |
| `scheduler` | `component=kube-scheduler` | `kube-scheduler` | `10259` | `/metrics` | verified HTTPS + token/CA files | none |
| `etcd` | `component=etcd` | `kube-etcd` | `2381` | `/metrics` | HTTP, no credentials | none |
| `api_server` | existing Service labels `component=apiserver,provider=kubernetes` | Service label `component` | named port `https` | `/metrics` | verified HTTPS + token/CA files + server name `kubernetes` | drop the kube-prometheus-stack noisy API histogram buckets |

Dedicated Service names are derived from the VMAgent name and component slug;
the corresponding VMServiceScrape adds `-victoria-metrics`. Every generated
component endpoint uses a 30-second interval and 10-second timeout. The
VictoriaMetrics output booleans mean that configuration was rendered, not that
the discovered target is healthy.

**Rationale**: Removing the Prometheus Helm release also removes both its
ServiceMonitors and the Services they select. A VMServiceScrape without a
replacement Service is therefore insufficient. Restricting the native pairs
to standalone mode avoids duplicate targets while the dual-backend converter
is consuming kube-prometheus-stack ServiceMonitors.

**Alternatives considered**:

- Keep `prometheus.enabled = true`: rejected because it preserves the hidden
  dependency that VM-only mode is intended to remove.
- Generate native component pairs in dual mode too: rejected because converted
  ServiceMonitors would create a second scrape path.
- Create only VMServiceScrapes: rejected because most selected Services are
  owned by kube-prometheus-stack and disappear with that release.

**Modern capability classification**: `supported`. The existing pinned
VictoriaMetrics Operator supports native `VMServiceScrape` resources and the
module-local ordered resources chart already provides their lifecycle boundary.

**Primary source**: [VictoriaMetrics Operator VMServiceScrape](https://docs.victoriametrics.com/operator/resources/vmservicescrape/)

## Resolved versions and compatibility

| Component | Version | Reason |
|---|---:|---|
| Terraform module runtime | `~> 1.3` | Existing public constraint |
| Terraform test runner | `>= 1.7, < 2.0` | Native provider mocking in focused tests |
| Helm provider | `~> 2.17` | Existing provider constraint |
| kube-prometheus-stack | `75.8.0` | Existing public default |
| kube-state-metrics | `7.8.1` (app `2.19.1`) | Aligns the independent release with the current EKS module pin while preserving the existing chart values contract |
| prometheus-node-exporter | `4.47.1` | Matches the bundled dependency being split out |
| VictoriaMetrics Cluster | `0.31.0` | Existing root default |
| VictoriaMetrics Operator | `0.67.2` | Existing pinned operator contract |
| Tempo | `1.23.3` | Existing root default |
| Loki | `6.34.0` | Existing root default |

No research item remains unresolved.
