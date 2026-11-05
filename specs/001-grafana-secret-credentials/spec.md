# Grafana Secret Credentials

## Goal

Keep Grafana database credentials in a Kubernetes Secret and never render their literal value into the Grafana ConfigMap.

## Acceptance criteria

- The rendered Grafana configuration contains an environment-variable reference, not the database password.
- The Grafana Helm chart receives the database password through its Secret-backed environment configuration.
- Existing database-enabled consumers retain their database host, user, name, and type configuration.
