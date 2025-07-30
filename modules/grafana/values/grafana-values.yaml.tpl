%{ if enabled_persistence }
persistence:
  enabled: ${enabled_persistence}
  storageClassName: gp2
  type: ${persistence_type}
  size: ${persistence_size}
  storageClassName: ${persistence_storage_class}
%{ if redundancy_enabled }
  accessModes:
    - ReadWriteMany
  existingClaim: ${ pvc_name }
%{ endif }
%{ endif }

grafana.ini:
  database: ${database}
  server:
    root_url: ${grafana_root_url}
    serve_from_sub_path: false
assertNoLeakedSecrets: false

serviceAccount:
  create: ${create_service_account}
  name: grafana-service-account
  annotations:
%{~ for k, v in service_account_annotations }
    ${k}: "${v}"
%{~ endfor }

ingress:
  enabled: true
  annotations:
%{~ for k, v in ingress_annotations }
    ${k}: "${v}"
%{~ endfor }
  hosts:
%{~ for h in ingress_hosts }
    - ${h}
%{~ endfor }
  path: ${ingress_path}
  pathType: ${ingress_path_type }
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
replicas: ${replicas}

resources:
  requests:
    cpu: ${request_cpu}
    memory: ${request_memory}
  limits:
    cpu: ${limit_cpu}
    memory: ${limit_memory}

serviceMonitor:
  enabled: true
  namespace: monitoring
  selector:
    matchLabels:
      release: prometheus

%{ if redundancy_enabled }
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: "kubernetes.io/hostname"
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: grafana

autoscaling:
  enabled: true
  minReplicas: ${hpa_min_replicas}
  maxReplicas: ${hpa_max_replicas}
  targetCPU: "70"
  targetMem: "60"

podDisruptionBudget:
  minAvailable: 1

%{ endif }
