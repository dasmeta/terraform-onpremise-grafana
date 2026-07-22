# Data Model: VictoriaMetrics Datasource Resilience

## Entity: Generated VictoriaMetrics Helm Values

**Represents**: The chart values emitted by the Terraform module for `vminsert`, `vmselect`, and `vmstorage`.

**Fields**:

- `vminsert.replicaCount`: existing write component replica count.
- `vminsert.extraArgs.replicationFactor`: default write replication factor.
- `vmselect.replicaCount`: existing query component replica count.
- `vmselect.extraArgs.replicationFactor`: default query replication factor.
- `vmselect.extraArgs.dedup.minScrapeInterval`: default query deduplication interval.
- `vmselect.extraArgs.search.skipSlowReplicas`: default slow replica skipping behavior.
- `vmstorage`: existing storage replica and persistent volume settings.

**Validation Rules**:

- Write and query replication factors must both default to `2`.
- Query deduplication must default to `1ms`.
- Slow replica skipping must default to `true`.
- Existing storage values must remain present and unchanged by the feature.

## Entity: Generated Grafana MySQL Helm Values

**Represents**: The chart values emitted by the Grafana submodule for the optional module-created MySQL release.

**Fields**:

- `primary.extraFlags`: existing MySQL primary command flags.
- `primary.persistence`: existing MySQL primary persistence settings.
- `primary.podAnnotations.karpenter.sh/do-not-disrupt`: default voluntary-disruption protection marker.
- `primary.pdb.create`: existing chart PDB creation toggle.
- `primary.pdb.minAvailable`: default minimum available primary pod count.
- `primary.pdb.maxUnavailable`: default maximum unavailable primary pod count.

**Validation Rules**:

- The MySQL primary pod annotation must default to `"true"`.
- The MySQL primary PDB must default to `minAvailable = 1`.
- The MySQL primary PDB must keep `maxUnavailable` empty when `minAvailable` is set.
