# Data Model: Default Service Alert Cleanup

## Alert Rule

**Purpose**: Represents one generated Grafana alert rule returned by the block-service alert module.

**Fields**:

- `name`: Human-readable alert name containing namespace and service name.
- `expr`: Prometheus-compatible expression or metric query.
- `pending_period`: Duration the condition must remain true before firing.
- `equation`: Comparison operator used by the Grafana rule.
- `threshold`: Numeric threshold for the rule.
- `labels`: Routing and severity labels merged from alert type defaults, service defaults, and alert overrides.
- `annotations`: Notification metadata such as impact, component, metric, resource, and threshold.

**Validation Rules**:

- Alert-specific labels override module alert type defaults.
- No running replica alerts use P1/critical defaults.
- Warning/degradation alerts use lower priority defaults unless overridden.

## Alert Type Label Defaults

**Purpose**: Module-owned map that assigns default priority and severity by alert category.

**Alert Categories**:

- `replicas_no`: P1/critical.
- `replicas_min`, `replicas_max`, `replicas_state`, `unavailable_replicas`, `job_failed`, `restarts`, `cpu`, `memory`: P2/warning.
- `network_in`, `network_out`: P3/warning.

**Relationships**:

- Merged into every generated alert rule before default labels and alert-specific labels.
- Can be overridden by caller-provided labels.

## Alert Opt-In

**Purpose**: Controls whether context-dependent or noisy alerts are generated.

**Rules**:

- HPA min/max alerts are generated only when explicitly enabled or when a manual threshold is configured.
- Network in/out anomaly alerts are generated only when explicitly enabled.
- Unavailable replicas alert follows default service alert enablement but is additionally gated by deployment workload type.

## Workload Type

**Purpose**: Identifies the Kubernetes workload kind used to choose expressions and workload-specific alerts.

**Supported Values in Scope**:

- `deployment`
- `daemonset`
- `statefulset`
- `cronjob`
- `job`

**Relationships**:

- Deployment workloads receive `kube_deployment_status_replicas_available` and `kube_deployment_status_replicas_unavailable` expressions.
- Non-deployment workloads do not receive the deployment unavailable replicas alert.

## DS-10938 Generic Signal

**Purpose**: Captures the reusable alert portion extracted from the broader Buycycle monitoring request.

**Fields**:

- Metric: `kube_deployment_status_replicas_unavailable`
- Condition: greater than `0`
- Pending period: `30s`
- Default labels: P2/warning

**Excluded Relationships**:

- Does not include Buycycle route-specific API/web, ingress, SSR, Karpenter, or EC2 credit monitoring.
