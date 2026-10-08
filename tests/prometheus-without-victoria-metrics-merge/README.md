# Prometheus values without VictoriaMetrics

This local-module compatibility fixture keeps VictoriaMetrics disabled while
passing scheduling values under `prometheus.prometheusSpec`. It proves the
non-VictoriaMetrics path leaves caller values intact and does not add a
module-managed `remoteWrite` entry. Grafana and the default disk-capacity alert
are disabled to keep the plan focused on Prometheus. No apply or live cluster is
required.

Run these commands from the repository root with Terraform and jq installed:

```bash
terraform -chdir=tests/prometheus-without-victoria-metrics-merge init -input=false
terraform -chdir=tests/prometheus-without-victoria-metrics-merge plan -out=tfplan -input=false
terraform -chdir=tests/prometheus-without-victoria-metrics-merge show -json tfplan \
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
          and ((.remoteWrite // []) | length == 0)
        )'
terraform -chdir=tests/prometheus-without-victoria-metrics-merge show -json tfplan \
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

The assertion decodes the planned Prometheus Helm values and requires the caller
node selector and toleration in the same Prometheus spec while requiring no
`remoteWrite` entries. It exits nonzero if either the caller values are missing
or a VictoriaMetrics-generated remote-write destination appears.

The second assertion is a topology guard. It examines both each planned Helm
resource address and the rendered release name, and fails if the plan adds a
standalone kube-state-metrics, node-exporter, VictoriaMetrics Operator, or
VMAgent release. Those components are outside this v1.28.0-based merge
backport.
