
grafana:
  enabled: false

prometheusOperator:
  enabled: true
  tls:
    enabled: false

prometheus:
  enabled: true
  prometheusSpec:
    scrapeInterval: "30s"
    scrapeTimeout: "10s"
    evaluationInterval: "30s"
    extraArgs:
    - --web.disable-exporter-metrics
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
  extraArgs:
    - --web.disable-exporter-metrics
  serviceMonitor:
    selfMonitor: false
  alertmanagerSpec:
    replicas: 1
    resources:
      requests:
        memory: 512Mi
        cpu: 250m
      limits:
        memory: 1Gi
        cpu: 500m

kubeApiServer:
  enabled: false

kube-state-metrics:
  enabled: true
  collectors:
    - configmaps
    - pods
    - cronjobs
    - deployments
    - endpoints
    - daemonsets
    - ingresses
    - nodes
    - persistentvolumeclaims
    - persistentvolumes
    - poddisruptionbudgets
    - replicasets
    - storageclasses

nodeExporter:
  enabled: true

prometheus-node-exporter:
  extraArgs:
    - --web.disable-exporter-metrics
  resources:
    requests:
      memory: 200Mi
      cpu: 100m
    limits:
      memory: 500Mi
      cpu: 200m

serviceMonitor:
  enabled: true
