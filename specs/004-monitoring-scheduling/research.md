# Research: monitoring scheduling propagation

## Confirmed flow

The AWS wrapper release `v1.1.10` forwards the existing `extra_configs` maps to `dasmeta/grafana/onpremise v1.28.5`. The generated consumer Terraform also contains the requested scheduling maps. The Helm provider recursively merges the ordered `values` documents, so VictoriaMetrics, Tempo, and Loki retain those maps as-is.

## Chosen approach

Keep the Helm provider's existing ordered values documents. Normalize Prometheus `extra_configs` through `yamldecode(jsonencode(...))` before it is inspected, so an object containing both `prometheus` and `alertmanager` has no Terraform conditional type mismatch.

The existing precedence remains generated defaults, caller values, then module-owned contract values. This preserves caller scheduling fields while retaining module-authoritative metrics integration fields.

## Alternatives rejected

- Add a new global scheduling variable: rejected because `extra_configs` is the established, documented interface and a new interface would unnecessarily widen the wrapper.
- Modify workloads manually after Helm apply: rejected because Helm would overwrite the change and Terraform state would drift.
- Replace Helm's ordered values documents with a Terraform deep-merge provider: rejected because it duplicates provider behavior, adds a third-party dependency, and would require Terraform 1.8 despite this module supporting Terraform 1.3+.

## Compatibility

No provider constraint, public variable shape, chart version, or resource identity changes. This is a patch-level behavioral correction.
