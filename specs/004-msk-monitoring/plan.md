# Implementation Plan: MSK CloudWatch Monitoring

**Branch**: `004-msk-monitoring` | **Date**: 2026-08-07 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/004-msk-monitoring/spec.md`

## Summary

Add first-class MSK monitoring to the dashboard module by introducing CloudWatch-based MSK widgets and a reusable `block/msk` dashboard block, following existing `block/rds` and `block/elasticache_redis` patterns. Optionally extend alert generation to support CloudWatch-backed MSK rules (offline partitions by default). Deliver tests and documentation with generic cluster identifiers only.

## Technical Context

**Language/Version**: Terraform HCL ~> 1.3  
**Primary Dependencies**: Grafana provider, existing `modules/dashboard` widget/base CloudWatch panel builder, `modules/alerts` rule group resources  
**Storage**: N/A (CloudWatch metrics consumed at query time via Grafana datasource)  
**Testing**: `terraform validate` at repo root and in new `modules/dashboard/tests/msk-cloudwatch/` example  
**Target Platform**: Grafana deployments with CloudWatch datasource configured by consumers  
**Project Type**: Infrastructure Terraform module repository  
**Performance Goals**: No regression for existing dashboard blocks when MSK is not configured  
**Constraints**: MSK only (no RDS changes); no consumer IAM/CloudWatch provisioning; generic examples only  
**Scale/Scope**: Dashboard widgets/block wiring, optional alert path, one test example, README updates

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Refined requirement gate**: PASS (`spec.md` complete; RDS explicitly out of scope).
- **Clarification gate**: PASS (P1 dashboards, P2 optional alerts documented).
- **Scope gate**: PASS (single repo feature; consumer CloudWatch setup out of scope).
- **Backward compatibility gate**: PASS (MSK block opt-in; existing blocks unchanged).
- **Reuse gate**: PASS (follow CloudWatch widget/block patterns already in repo).

## Project Structure

### Documentation (this feature)

```text
specs/004-msk-monitoring/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── msk-dashboard-block-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md                  # created by /speckit.tasks
```

### Source Code (repository root)

```text
modules/dashboard/
  modules/widgets/msk/
    cpu/ memory/ throughput_in/ throughput_out/
    partitions/ offline_partitions/ consumer_lag/
  modules/blocks/msk/
    variables.tf output.tf README.md
  widgets-msk.tf              # widget module wiring
  widgets_blocks.tf           # block_msk module
  locals.tf                   # blocks_results.msk + widget panel merge
  alerts.tf                   # optional block_msk_alerts wiring (P2)
  modules/alerts/block-msk/   # optional MSK alert rule generator (P2)
modules/alerts/modules/rules/
  main.tf variables.tf        # cloudwatch datasource branch (P2)
modules/dashboard/tests/msk-cloudwatch/
  0-setup.tf 1-example.tf README.md
README.md                     # MSK block usage example
```

**Structure Decision**: All MSK dashboard behavior lives in `modules/dashboard` mirroring RDS/ElastiCache CloudWatch widgets. Optional alerting extends dashboard alert outputs and the shared rules module only when CloudWatch query models are required.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| CloudWatch alert query branch in rules module | Grafana CloudWatch alerts use metric query models, not PromQL `expr` | Reusing prometheus-only rule template cannot evaluate MSK CloudWatch metrics |
| Separate MSK widget modules per metric | Matches existing repo convention (`rds/cpu`, `elasticache_redis/cpu`) | Single mega-widget would break composability and block layout patterns |

## Post-Design Constitution Re-check

- **Refined requirement gate**: PASS
- **Clarification gate**: PASS
- **Scope gate**: PASS
- **Backward compatibility gate**: PASS
- **Reuse gate**: PASS
