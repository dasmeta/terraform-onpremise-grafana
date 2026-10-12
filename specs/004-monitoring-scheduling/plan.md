# Monitoring Scheduling Propagation Implementation Plan

**Goal:** Preserve caller scheduling values for Prometheus, Alertmanager, VictoriaMetrics, Tempo, and Loki without changing their public `extra_configs` interfaces.

**Architecture:** Retain the existing ordered `helm_release.values` documents. Helm provider v2.17 recursively merges maps in order, so generated defaults apply first, caller values next, and module-owned contract values last. Normalize Prometheus caller values by choosing between serialized YAML strings before decoding, preventing Terraform from attempting to unify heterogeneous top-level object shapes.

**Tech Stack:** Terraform HCL, HashiCorp Helm provider, native Terraform tests with mocked providers.

## Scope

- Target: `terraform-onpremise-grafana` current `1.29.1` implementation.
- Public interface: established component `extra_configs` maps; unchanged.
- Module-owned contract fields: collector enablement, remote-write URLs, service endpoints, and monitoring enablement remain authoritative.
- Out of scope: Grafana/MySQL, Promtail, node-exporter, chart upgrades, and manual cluster changes.

## Files

```text
modules/prometheus/locals.tf
  # normalize heterogeneous caller extra_configs before inspection
tests/monitoring-scheduling/
  0-setup.tf
  1-scheduling-propagation.tftest.hcl
README.md
specs/004-monitoring-scheduling/
```

## Steps

1. Add isolated Terraform plan tests with a `{ workload = "monitoring" }` selector and `NoSchedule` toleration for the four target child modules.
2. Assert the existing values-list ordering rather than a synthetic single map:
   - Prometheus caller values document retains Prometheus/Alertmanager scheduling and remote-write; the later module contract enables the collector.
   - VictoriaMetrics, Tempo, and Loki caller documents retain scheduling; their later documents retain respective endpoint, metrics, and monitoring contracts.
3. Demonstrate the baseline Prometheus failure for a heterogeneous six-key `extra_configs` object.
4. Change only Prometheus `caller_extra_configs` to select between serialized YAML strings before `yamldecode(...)`, preserving the existing dynamic-object normalization before local inspection.
5. Run formatting, root validation, and the focused scheduling test suite.

## Acceptance criteria

- A caller can provide Prometheus and Alertmanager scheduling values in one `extra_configs` object without a Terraform type error.
- Scheduling values remain present in the caller Helm values document for all target modules.
- Later module-owned values preserve the integration contract without overriding scheduling values.
- No new provider, Terraform version requirement, or public input is introduced.

## Release handoff

Publish a patch release of `dasmeta/grafana/onpremise`, then update the AWS wrapper pin and consumer IaC after plan review. Rollback is a version-pin reversal.
