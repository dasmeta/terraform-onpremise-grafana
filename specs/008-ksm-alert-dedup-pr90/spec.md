# PR #90: reliable HPA replica alerts

## Context

DS-12693 and DS-13964 report Grafana `DatasourceError` when overlapping kube-state-metrics series make raw PromQL vector matches ambiguous. PR #90 proposes aggregation but its current implementation breaks cronjob/job planning and conflicts with newer `main` changes.

## Requirements

- Aggregate workload and HPA object metrics before min/max replica comparisons so scraper labels cannot produce duplicate match series.
- Preserve alert behavior for deployment, daemonset, statefulset, cronjob, and job blocks. Optional alerts must not evaluate absent workload metrics.
- Numeric min/max thresholds must generate valid PromQL without vector matching against scalars.
- `replicas_no` must also avoid duplicate alert instances for duplicate scraper series.
- Preserve existing consumer inputs and current `main` behavior, including stable UIDs and legacy query options.
- Cover generated expressions and workload-type planning in Terraform tests.

## Acceptance

- `terraform test`, `terraform validate`, and `terraform fmt -check` pass for the affected module.
- Generated PromQL for HPA comparisons is unambiguous and numeric-threshold comparisons parse.
- Plan tests pass for all five workload types, with default deployment alerts enabled.
- PR branch merges current `main` without conflicts. Production deployment and 24-hour observation remain separate approved operations.
