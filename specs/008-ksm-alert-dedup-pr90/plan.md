# Plan

## Baseline

Downstream repository: `dasmeta/terraform-onpremise-grafana`; affected module: `modules/dashboard/modules/alerts/block-service`. Existing PR #90 contains the initial fix and test. Current `main` adds stable UID and legacy query behavior, and already defines `unavailable_replicas_expr`. This is a focused behavior fix with no input-interface change, provider change, or new upstream module.

## Implementation

1. Merge current `main` into the PR branch and resolve only overlapping alert-module code, keeping both sets of behavior.
2. Keep workload aggregation safe for cronjob/job and missing workload metrics. Aggregate HPA and workload inputs before vector matching.
3. Correct numeric threshold branches and deduplicate `replicas_no`.
4. Expand native Terraform tests across workload types, default deployment behavior, and threshold expression shapes.
5. Run module tests, validation, format checks, and root validation. Document label-identity change and production rollout risk in PR #90.

## Risks and rollout

Aggregation removes scraper labels from alert instance identity. Existing silences using those labels may stop matching, and firing instances may resolve and re-fire during deployment. Review such silences and deploy the updated Terraform-managed rule only after production approval; retain the prior version as rollback. Confirm live rule health, one object-level result, real low-replica detection, and 24 hours without `DatasourceError` after rollout.

## Governance

Use the repository's current module layout and native `.tftest.hcl` tests. Shared module standards come from the local Terraform module developer skill. The Speckit package is this directory and accompanies the module change. No interface widening or breaking input change is planned.
