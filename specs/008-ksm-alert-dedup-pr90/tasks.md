# Tasks

- [x] Merge current `main` into the PR branch and resolve conflicts while preserving stable UID and legacy-query behavior.
- [x] Make HPA workload aggregation safe for all supported workload types.
- [x] Deduplicate `replicas_no` and fix scalar min/max threshold expressions.
- [x] Add plan tests for all workload types, default deployment, and threshold branches.
- [x] Run Terraform format, tests, and validation; inspect final PR diff and checks.
- [x] Update PR #90 with review responses, validation, and rollout risk; push the fixed branch.
- [x] Preserve fractional B values in modules/alerts/modules/contact-points/main.tf and validate Terraform syntax. Live firing/resolved notification verification remains a rollout gate.
