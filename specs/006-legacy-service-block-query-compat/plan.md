# Legacy Service-Block Query Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow an existing application dashboard to retain its deployed service status-panel and service-alert PromQL expressions without changing the module's default behavior.

**Architecture:** Add one optional, dashboard-scoped `defaults.query_compatibility.legacy_service_block_queries` switch. The dashboard passes it only into generated `block/service` replica widgets and `block-service` alert rules; those leaves choose the recorded expression contract while all unconfigured consumers keep v1.31.0 rendering.

**Tech Stack:** Terraform HCL ~> 1.3, Grafana provider ~> 4.0, Terraform native tests, `terraform fmt`, `terraform validate`, `terraform test`, and pre-commit Terraform docs.

---

## Pre-change evidence and scope

- **Starting revision:** `v1.31.0` (`5781e68`), in the `terraform-onpremise-grafana` repository.
- **Production evidence:** The recorded production plan has 16 changed service phase expressions in the application dashboard resource, plus two expressions in its service alert rule group.
- **Exact compatibility contract:** service phase panels use `pod=~"<service>-.*"`; service phase alerts use `^<service>(-[^-]+)?-[^-]+$`; service memory alerts use `container_memory_usage_bytes`.
- **Default contract:** remains the existing modern primary/canary-aware phase selector and `container_memory_working_set_bytes` memory metric.
- **Interface decision:** one nested optional boolean is a narrow extension to the existing `query_compatibility` grouping. It is not a raw PromQL override and does not expose an upstream pass-through surface.
- **Modern Capabilities Rule:** `supported` / not provider-sensitive. This feature changes only PromQL strings rendered by an existing Grafana resource and does not introduce a provider capability or change provider constraints.
- **Module-change gate:** pass once this `spec.md`, this plan, and `tasks.md` are committed with tests and documentation.
- **Out of scope:** raw dashboard JSON, resource-address moves, Grafana scheduling, alert metadata/threshold changes, and consumer YAML until a released on-premise and AWS-wrapper version exists.

## Files and responsibilities

| File | Responsibility |
|---|---|
| `modules/dashboard/locals.tf` | Read the nested compatibility selection once, defaulting safely to false. |
| `modules/dashboard/widgets_blocks.tf` | Pass the selection only to generated service blocks. |
| `modules/dashboard/modules/blocks/service/variables.tf` | Declare the block-local compatibility input. |
| `modules/dashboard/modules/blocks/service/locals.tf` | Mark only generated `container/replicas` widgets as requiring the deployed service selector. |
| `modules/dashboard/widgets-container.tf` | Pass the marker to the replicas widget without changing other container widgets. |
| `modules/dashboard/modules/widgets/container/replicas/{variables.tf,base.tf}` | Render the exact legacy service selector or preserve the existing legacy/modern selector behavior. |
| `modules/dashboard/alerts.tf` | Pass the dashboard selection to generated service alert modules. |
| `modules/dashboard/modules/alerts/block-service/{variables.tf,locals.tf,outputs.tf}` | Choose only the service-alert phase selector and memory metric required by the recorded contract. |
| `modules/dashboard/tests/2-service-block-query-contract.tftest.hcl` | Prove compatibility-on and compatibility-off expressions through the public dashboard module. |
| `modules/dashboard/variables.tf`, `variables.tf`, `README.md` | Describe the temporary, opt-in setting and regenerate module documentation. |

## Task 1: Capture the failing public contract

**Files:**

- Create: `modules/dashboard/tests/2-service-block-query-contract.tftest.hcl`

- [ ] **Step 1: Add the compatibility-on test before implementation.** Use the public `../../modules/dashboard` module, mocked Grafana/random providers, one `block/service` row named `example-service` in namespace `prod`, and:

```hcl
defaults = {
  query_compatibility = {
    legacy_service_block_queries = true
  }
}
```

Assert `output.widget_result` contains both `sum(kube_pod_status_phase{namespace="prod", pod=~"example-service-.*"})` expressions and `output.widget_alert_rules` contains the legacy phase matcher and `container_memory_usage_bytes` memory expression.

- [ ] **Step 2: Run the new test and confirm RED.**

Run: `terraform -chdir=modules/dashboard init -backend=false && terraform -chdir=modules/dashboard test -filter=tests/2-service-block-query-contract.tftest.hcl`

Expected: FAIL because `legacy_service_block_queries` is not yet wired and modern expressions are rendered.

- [ ] **Step 3: Add the default-contract run to the same test.** Omit `legacy_service_block_queries` and assert the v1.31.0 phase selector and `container_memory_working_set_bytes` remain present.

- [ ] **Step 4: Re-run and confirm the default assertion passes while the compatibility assertion remains RED.** This proves the test isolates the missing compatibility behavior rather than failing from provider setup.

## Task 2: Implement dashboard and widget compatibility

**Files:**

- Modify: `modules/dashboard/locals.tf`
- Modify: `modules/dashboard/widgets_blocks.tf`
- Modify: `modules/dashboard/modules/blocks/service/variables.tf`
- Modify: `modules/dashboard/modules/blocks/service/locals.tf`
- Modify: `modules/dashboard/widgets-container.tf`
- Modify: `modules/dashboard/modules/widgets/container/replicas/variables.tf`
- Modify: `modules/dashboard/modules/widgets/container/replicas/base.tf`

- [ ] **Step 1: Define the dashboard-scoped local.**

```hcl
legacy_service_block_queries = try(tobool(var.defaults.query_compatibility.legacy_service_block_queries), false)
```

- [ ] **Step 2: Propagate the local to `module "block_service"`.** Add only `legacy_service_block_queries = local.legacy_service_block_queries`; do not add it to any other block module.

- [ ] **Step 3: Mark only the service block's replicas widget.** Add a `legacy_service_block_queries` boolean variable to the service block and add that key only to its generated `container/replicas` widget object.

- [ ] **Step 4: Add the leaf selector branch.** The replicas widget receives its own optional boolean and chooses selectors in this precedence order:

```hcl
pod_matcher = var.legacy_service_block_queries ? "${var.container}-.*" : (
  var.legacy_dashboard_queries ? "^${var.container}-[^-]+-[^-]+$" : "^${var.container}(-(primary|canary))?-[^-]+-[^-]+$"
)
```

- [ ] **Step 5: Run `terraform fmt` on every changed Terraform file and rerun the focused test.**

Expected: compatibility-on dashboard assertions pass; the no-setting dashboard assertion remains green.

## Task 3: Implement service-alert compatibility

**Files:**

- Modify: `modules/dashboard/alerts.tf`
- Modify: `modules/dashboard/modules/alerts/block-service/variables.tf`
- Modify: `modules/dashboard/modules/alerts/block-service/locals.tf`
- Modify: `modules/dashboard/modules/alerts/block-service/outputs.tf`

- [ ] **Step 1: Pass the dashboard local only into `module "block_service_alerts"`.**

```hcl
legacy_service_block_queries = local.legacy_service_block_queries
```

- [ ] **Step 2: Declare the optional boolean in the alert submodule.** It defaults to false and describes that it preserves deployed service phase and memory expressions during an upgrade.

- [ ] **Step 3: Derive the two alert-only values in `locals.tf`.**

```hcl
replicas_state_pod_matcher = var.legacy_service_block_queries ? "^${local.workload_name}(-[^-]+)?-[^-]+$" : "^${local.workload_name}(-(primary|canary))?(-[^-]+)?-[^-]+$"
memory_metric              = var.legacy_service_block_queries ? "container_memory_usage_bytes" : "container_memory_working_set_bytes"
```

- [ ] **Step 4: Replace only the phase-status and memory expressions in `outputs.tf` with those locals.** Leave all alert names, groups, labels, pause behavior, thresholds, and other query expressions untouched.

- [ ] **Step 5: Run the focused native test again.**

Expected: all compatibility-on and default-contract assertions pass.

## Task 4: Document and verify the release candidate

**Files:**

- Modify: `modules/dashboard/variables.tf`
- Modify: `variables.tf`
- Modify: `README.md` (generated)

- [ ] **Step 1: Document `defaults.query_compatibility.legacy_service_block_queries`.** State it is opt-in, defaults false, preserves current service-panel/service-alert contracts during an upgrade, and can be removed in a future major release.

- [ ] **Step 2: Regenerate Terraform docs using the repository pre-commit hook.**

Run: `pre-commit run terraform_docs --all-files`

- [ ] **Step 3: Run formatting and static validation.**

Run: `terraform fmt -check -recursive && terraform init -backend=false && terraform validate`

Expected: exit 0.

- [ ] **Step 4: Run all native test files and the repository hook suite.**

Run: `terraform -chdir=modules/dashboard test && pre-commit run --all-files`

Expected: exit 0 with the new service-block contract test discovered.

- [ ] **Step 5: Compare the generated expressions against the recorded plan evidence.** Confirm all 16 dashboard status expressions use `<service>-.*`, and the service-alert phase and memory expressions match the deployed values.

- [ ] **Step 6: Commit only the 006 Speckit package, source, test, and generated documentation.** Do not include unrelated `.specify` bootstrap files from the older worktree or generated Terraform output.

## Rollout sequence after this module change

1. Release the on-premise module after the module PR is approved.
2. Bump and release the `dasmeta/grafanav12/aws` wrapper to that immutable on-premise tag.
3. In the consumer configuration, add `legacy_service_block_queries: true` beside the already-selected `legacy_dashboard_queries: true` and update the wrapper version.
4. Regenerate Terraform only through the supported workflow, then inspect the plan. The application dashboard resource and its nested service alert rule groups must have no planned changes.

## Plan self-review

- **Spec coverage:** FR-001 through FR-007 map respectively to Tasks 2, 2/3, 3, 2/3 tests, Task 3 boundary, Task 4 documentation, and Tasks 1/4 validation.
- **Compatibility:** default values and current branches are explicitly preserved; no state address or provider version changes are planned.
- **Scope:** all source modifications are within the on-premise module; wrapper and consumer updates are release-consumer follow-up, not included in this branch.
- **Placeholder scan:** no unresolved decisions or placeholder implementation steps remain.
