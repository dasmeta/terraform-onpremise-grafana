# Research: Default Service Alert Cleanup

## Decision: Use alert type labels instead of a global P1 default

**Rationale**: The previous dashboard-level default label made every generated service alert appear P1, including CPU, memory, HPA, network, and restart warnings. Alert severity should be determined by the impact of the alert type and remain overrideable by callers.

**Alternatives considered**:

- Keep global P1 and rely on notification policy exceptions. Rejected because it preserves noisy default metadata.
- Require every consumer to set labels manually. Rejected because defaults should be safe without per-service tuning.

## Decision: Keep no running replica as P1/critical

**Rationale**: A service with zero running/available replicas is an immediate outage signal and should keep the highest default priority.

**Alternatives considered**:

- Downgrade all service alerts to P2/warning. Rejected because it would understate full service outage conditions.

## Decision: Gate HPA min/max rules by explicit enablement or manual thresholds

**Rationale**: HPA-based min/max alerts require HPA context. Creating them for every service causes invalid or noisy alerts for services without HPA. Manual thresholds remain useful even when HPA metrics are not available.

**Alternatives considered**:

- Always generate HPA rules and rely on NoData behavior. Rejected because NoData is still noisy and misleading.
- Disable HPA alerts completely. Rejected because some services need explicit HPA saturation alerts.

## Decision: Make network anomaly alerts opt-in

**Rationale**: Network anomaly alerts are useful for selected services but noisy as a default for all service blocks. They also depend on traffic shape and baseline stability.

**Alternatives considered**:

- Keep network anomaly alerts enabled with lower priority. Rejected because lower priority still creates unnecessary alert volume.
- Remove network alerts entirely. Rejected because explicit opt-in keeps the feature available.

## Decision: Add deployment unavailable replicas alert as a default deployment signal

**Rationale**: DS-10938 identified deployment unavailable replicas as a generic, reusable Kubernetes health signal. Alerting on unavailable replicas greater than `0` for `30s` can catch rollout or capacity degradation before a total no-replica outage.

**Alternatives considered**:

- Do not add the alert because `replicas_no` exists. Rejected because `replicas_no` only covers full outage when available replicas are zero, while unavailable replicas can indicate partial degradation.
- Add the full DS-10938 scope. Rejected because route-specific latency, SSR, Karpenter, EC2 credit, and ingress details are customer/service-specific and do not belong in default module alerts.

## Decision: Limit unavailable replicas to deployment workloads

**Rationale**: The selected metric is deployment-specific and should not be generated for daemonset, statefulset, job, or cronjob workload types.

**Alternatives considered**:

- Add equivalent rules for every workload type in this pass. Rejected because each workload type requires a matching metric and semantics review.
