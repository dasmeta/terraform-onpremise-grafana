
persistence:
  enabled: ${enabled_persistence}
  type: ${persistence_type}
  size: ${persistence_size}

ingress:
  enabled: true
  annotations:
%{~ for k, v in ingress_annotations }
    ${k}: "${v}"
%{ endfor }
  hosts:
%{~ for h in ingress_hosts }
    - ${h}
%{ endfor }
  path: ${ingress_path}
  pathType: ${ingress_path_type }
  tls:
%{~ for item in tls_secrets }
    - secretName: ${item.secret_name}
      hosts:
%{~ for host in item.hosts }
        - ${host}
%{~ endfor ~}
%{ endfor }
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
