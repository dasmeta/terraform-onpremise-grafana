tempo:
  image:
    tag: ${tempo_image_tag}

  service:
    enabled: true
    type: ClusterIP

  storage:
    trace:
      backend: ${storage_backend}  # "s3" or "local"
%{ if storage_backend == "s3" }
      s3:
        bucket: ${bucket_name}
        endpoint: s3.${region}.amazonaws.com
        region: ${region}
        insecure: false
%{ else }
      local:
        path: /var/tempo/traces
%{ endif }

  persistence:
    enabled: ${persistence_enabled}
    size: ${persistence_size}
    storageClassName: ${persistence_class}

  metricsGenerator:
    enabled: ${enable_metrics_generator}

  ingress:
    enabled: ${enable_ingress}
    annotations:
%{~ for k, v in ingress_annotations }
      ${k}: "${v}"
%{~ endfor }
    hosts:
%{~ for h in ingress_hosts }
      - ${h}
%{~ endfor }
    path: ${ingress_path}
    pathType: ${ingress_path_type}

serviceMonitor:
  enabled: ${enable_service_monitor}

serviceAccount:
  create: true
  name: ${service_account_name}
  annotations:
  %{for k, v in service_account_annotations }
      ${k}: "${v}"
  %{~ endfor }
