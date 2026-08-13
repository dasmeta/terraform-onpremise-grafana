# Research: VictoriaMetrics Datasource Resilience

## Decision: Use VictoriaMetrics Cluster RF=2 For Writes And Queries

**Rationale**: DS-11630 final validation showed one-at-a-time `vmstorage` replacement stopped producing the previous datasource error pattern when `vminsert` and `vmselect` both used replication factor 2.

**Alternatives considered**: PDBs help voluntary evictions but do not prevent involuntary spot/node loss. `preStop` helps service shutdown but does not solve fixed-shard storage lookup failures. Alert rule state changes reduce noise but do not fix the query path.

## Decision: Use Chart `extraArgs` Defaults Instead Of New Public Variables

**Rationale**: The wrapper already allows `extra_configs` overrides. Adding narrow defaults in generated Helm values keeps the interface stable and avoids broad pass-through inputs.

**Alternatives considered**: Adding explicit replication variables would widen the public interface for a value now intended to be the module default.

## Decision: Test Generated Helm Values With `terraform test`

**Rationale**: The behavior is represented by generated chart values before apply, so a plan-time Terraform test can verify the default without a Kubernetes cluster.

**Alternatives considered**: Rendering the Helm chart directly is useful for exploration, but the regression guard should exercise this Terraform module's generated values.

## Decision: Persist Grafana MySQL Pod/PDB Mitigation In Chart Values

**Rationale**: DS-11630 recorded the module-created Grafana MySQL primary as a singleton dependency that should not be voluntarily disrupted. The Bitnami MySQL chart supports this natively through `primary.podAnnotations` and `primary.pdb`.

**Alternatives considered**: Keeping the mitigation only in `mysql_extra_configs` leaves every consumer to copy the same YAML. Direct database mutations are rejected because Grafana alert-rule state should be managed through Terraform resources rather than SQL edits.
