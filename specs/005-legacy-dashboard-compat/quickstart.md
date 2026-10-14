# Validation Guide: Legacy Dashboard Query Compatibility

## Prerequisites

- Terraform `>= 1.7, < 2.0` for native Terraform tests.
- Provider plugins available through the repository lockfile or configured provider cache.
- No Grafana credentials are required for the focused tests because they use a mocked Grafana provider.

## Focused module checks

From the repository root:

```sh
terraform fmt -check -recursive
cd tests/dashboard-query-compatibility
terraform init -backend=false -lockfile=readonly
terraform test
```

Expected result: the fixture verifies both modern-default and legacy-enabled query targets across all nine affected widget modules, dashboard-level isolation, and alert-rule non-interference.

## Documentation and static checks

Run the repository’s Terraform documentation and pre-commit checks after source and README updates. Generated documentation must include the nested configuration example without removing existing input documentation.

## Downstream release validation

1. Release the reviewed on-premises Grafana module.
2. Update and release `dasmeta/terraform-aws-grafanav12` to consume that release.
3. In consumer Grafana YAML, add the compatibility selection only to the target dashboard.
4. Regenerate the derived Terraform using the approved workflow; do not edit generated Terraform manually.
5. Run the Terraform Cloud plan and confirm the target `grafana_dashboard.metrics` resource has no dashboard JSON update. Review any remaining alert changes independently.
6. Apply only after the reviewed plan matches this expectation, then confirm Grafana still shows the existing dashboard layout and query behaviour.
