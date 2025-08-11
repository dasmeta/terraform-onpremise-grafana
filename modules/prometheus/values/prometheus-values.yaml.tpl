
grafana:
  enabled: false

prometheusOperator:
  enabled: true
  tls:
    enabled: false

prometheus:
  enabled: true
  prometheusSpec:
    replicas: ${replicas}
    retention: ${retention_days}
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: ${storage_class_name}
          accessModes:
    %{~ for mode in access_modes }
            - ${mode}
    %{~ endfor }
          resources:
            requests:
              storage: ${storage_size}
    resources:
      requests:
        memory: ${request_mem}
        cpu: ${request_cpu}
      limits:
        memory: ${limit_mem}
        cpu: ${limit_cpu}

    enableRemoteWriteReceiver: true

    additionalScrapeConfigs:
    - job_name: "annotation-scrape"
      kubernetes_sd_configs:
        - role: pod
      relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: "true"
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          action: replace
          target_label: __address__
          regex: (.+):(?:\d+);(.+)
          replacement: $1:$2
    - job_name: 'kubernetes-service-monitor'
      kubernetes_sd_configs:
        - role: service
      relabel_configs:
        - action: keep
          source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
          regex: "true"
        - action: replace
          source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
          target_label: __metrics_path__
        - action: replace
          source_labels: [__meta_kubernetes_service_annotation_prometheus_io_port]
          target_label: __metrics_port__



%{ if ingress_enabled }
  ingress:
    enabled: ${ingress_enabled}
    ingressClassName: ${ingress_class}
    pathType: ${ingress_path_type}
    annotations:
%{~ for k, v in ingress_annotations }
      ${k}: "${v}"
%{~ endfor }
    hosts:
%{~ for h in ingress_hosts }
    - ${h}
%{~ endfor }
%{~ for path in ingress_paths }
    paths:
    - ${path}
%{~ endfor}
%{ if length(tls_secrets) > 0 }
    tls:
%{~ for item in tls_secrets }
    - secretName: ${item.secret_name}
      hosts:
%{~ for host in item.hosts }
      - ${host}
%{~ endfor ~}
%{ endfor }
%{ endif }
%{ endif }


alertmanager:
  enabled: ${enable_alertmanager}
  alertmanagerSpec:
    replicas: 1
    resources:
      requests:
        memory: 512Mi
        cpu: 250m
      limits:
        memory: 1Gi
        cpu: 500m

kube-state-metrics:
  enabled: true

nodeExporter:
  enabled: true

prometheus-node-exporter:
  resources:
    requests:
      memory: 200Mi
      cpu: 100m
    limits:
      memory: 500Mi
      cpu: 200m

serviceMonitor:
  enabled: true
