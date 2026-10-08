# Prometheus values with VictoriaMetrics

This local-module regression fixture requires the caller's node selector and
single toleration to survive alongside the generated VictoriaMetrics remote-write
URL. Grafana and the default disk-capacity alert are disabled to keep the plan
focused on the two metrics releases. No apply or live cluster is required.

Run these commands from the repository root with Terraform and jq installed:

```bash
terraform -chdir=tests/prometheus-victoria-metrics-merge init -input=false
terraform -chdir=tests/prometheus-victoria-metrics-merge plan -out=tfplan -input=false
terraform -chdir=tests/prometheus-victoria-metrics-merge show -json tfplan \
  | jq -e '
      [ .resource_changes[]
        | select(.type == "helm_release" and .name == "prometheus")
        | .change.after.values[]?
        | (fromjson? // {})
        | .prometheus.prometheusSpec? // empty
      ] as $specs
      | any($specs[];
          .nodeSelector.workload == "monitoring"
          and (.tolerations // [] | any(.[];
            .key == "workload"
            and .operator == "Equal"
            and .value == "monitoring"
            and .effect == "NoSchedule"
          ))
          and (.remoteWrite // [] | any(.[];
            .url == "http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write"
          ))
        )'
terraform -chdir=tests/prometheus-victoria-metrics-merge show -json tfplan \
  | jq -e '
      [ .resource_changes[]
        | select(.type == "helm_release")
        | { address, release_name: (.change.after.name // .name) }
      ]
      | all(.[];
          ((.address + " " + .release_name)
            | test("kube-state-metrics|node-exporter|victoria-metrics-operator|vmagent"; "i")
            | not)
        )'
```

The assertion locates the planned `helm_release.prometheus` values, decodes each
JSON document, and requires the scheduling values and generated URL in the same
Prometheus spec. On the unmodified v1.28.0 baseline, the plan should succeed but
the assertion should print `false` and exit nonzero: the generated remote-write
URL is present, while the caller's node selector and tolerations are missing.

Baseline verification on 2026-10-08 used Terraform 1.15.4, Helm provider 2.17.0,
and jq 1.6. Initialization and planning succeeded (`3 to add, 0 to change, 0 to
destroy`); the assertion printed `false` and exited 1. Inspecting the decoded
Prometheus spec confirmed `nodeSelector` and `tolerations` were absent and
`remoteWrite[0].url` matched the URL above. The third planned resource was the
module's default JSON Grafana dashboard; it did not block planning.

The second assertion is a topology guard. It examines both each planned Helm
resource address and the rendered release name, and fails if the plan adds a
standalone kube-state-metrics, node-exporter, VictoriaMetrics Operator, or
VMAgent release. Those components are outside this v1.28.0-based merge
backport.

In the local sandbox, initialization required permission to access the provider
registry, and planning/show required permission for provider processes to run.
No module-source changes or provider credential overrides were needed.
