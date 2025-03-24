
grafana:
  enabled: false

prometheusOperator:
  enabled: true
  tls:
    enabled: false

prometheus:
  enabled: true
  prometheusSpec:
    replicas: 2
    retention: ${retention_days}
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: ${storage_class_name}
          accessModes: ["ReadWriteMany"]
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
    serviceMonitorSelectorNilUsesHelmValues: false

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
