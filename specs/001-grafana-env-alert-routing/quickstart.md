# Quickstart: Multi-Environment Grafana Alert Routing

## 1) Prepare feature branch
- Ensure branch is `001-grafana-env-alert-routing`.
- Confirm Speckit docs exist under `specs/001-grafana-env-alert-routing/`.

## 2) Configure same-cluster mode
- Define environments mapped by namespace.
- Define per-environment channel mapping.
- Apply module changes and validate:
  - dashboards render per namespace variable,
  - alerts route to matching environment channels only.

## 3) Execute acceptance checks
- Use at least 3 environments.
- Trigger one test alert per environment.
- Confirm:
  - each alert reaches only configured channel,
  - env A never reaches env B channel.
- Trigger one alert with unresolved environment identity and confirm:
  - it reaches `ops-fallback`,
  - it does not reach environment-specific channels.

## 4) Mirror to AWS v12 module
- Apply equivalent variable/routing behavior in `../terraform-aws-grafanav12`.
- Re-run acceptance checks for mirrored module examples.

## 6) Validation evidence (implementation session)

- Same-cluster matcher-based routing scenario:
  - Command: `terraform -chdir=tests/multi-environment-alert-routing init -backend=false -input=false`
  - Command: `terraform -chdir=tests/multi-environment-alert-routing validate`
  - Result: configuration valid.
- AWS v12 mirror scenario:
  - Command: `terraform -chdir=../terraform-aws-grafanav12/tests/base init -backend=false -input=false`
  - Command: `terraform -chdir=../terraform-aws-grafanav12/tests/base validate`
  - Result: configuration valid (with upstream module deprecation warnings unrelated to matcher routing behavior).
