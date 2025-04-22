
persistence:
  enabled: ${enabled_persistence}
  type: ${persistence_type}
  size: ${persistence_size}
  accessModes:
    - ReadWriteMany
%{ if redundency_enabled }
  existingClaim: ${ pvc_name }
%{ endif }

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

%{ if redundency_enabled }
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
