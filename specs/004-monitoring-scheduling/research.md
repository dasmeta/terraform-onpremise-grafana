# Research: monitoring scheduling propagation

## Confirmed flow

The AWS wrapper release `v1.1.10` forwards the existing `extra_configs` maps to `dasmeta/grafana/onpremise v1.28.5`. The generated consumer Terraform also contains the requested scheduling maps. The loss therefore occurs when the on-premise child modules provide multiple independently encoded Helm values documents.

## Chosen approach

Each affected child module will deep-merge its generated defaults, caller-provided custom values, and module-owned contract values into one map before JSON encoding it for `helm_release.values`.

Merge precedence is ordered from generated defaults to caller values to module-owned contract values. This preserves caller scheduling fields while retaining module-authoritative metrics integration fields.

## Alternatives rejected

- Add a new global scheduling variable: rejected because `extra_configs` is the established, documented interface and a new interface would unnecessarily widen the wrapper.
- Modify workloads manually after Helm apply: rejected because Helm would overwrite the change and Terraform state would drift.
- Depend on Helm's merge of multiple independent values documents: rejected because the production evidence shows the final applied values lose callers' maps at this boundary; explicit Terraform composition makes the contract testable.

## Compatibility

No provider constraint, public variable shape, chart version, or resource identity changes. This is a patch-level behavioral correction.
