deploymentMode: "SingleBinary"

%{ if create_service_account }
serviceAccount:
  create: ${create_service_account}
  name: ${service_account_name}
  annotations:
%{for k, v in service_account_annotations }
    ${k}: "${v}"
%{~ endfor }
%{ endif ~}


# disable chart test and related canary setup(TODO: check this components, maybe they are something to have enabled)
test:
  enabled: false
lokiCanary:
  enabled: false

# TODO: for now disabled, it seems we can use this option to expose loki endpoint, it has options to configure ingress/auth
gateway:
  enabled: ${ingress_enabled}
  ingress:
    enabled: ${ingress_enabled}
    ingressClassName: ${ingress_type}
    annotations:
%{ for k, v in ingress_annotations ~}
      ${k}: "${v}"
%{ endfor ~}
    hosts:
%{~ for h in ingress_hosts }
      - host: ${h}
        paths:
          - path: ${ingress_path}
            pathType: ${ingress_path_type }
%{~ endfor ~}
%{ if length(ingress_tls_secrets) > 0 }
    tls:
%{~ for item in ingress_tls_secrets }
      - secretName: ${item.secret_name}
        hosts:
%{~ for host in item.hosts }
          - ${host}
%{~ endfor ~}
%{~ endfor ~}
%{ endif }

singleBinary:
%{ if persistence_enabled }
  persistence:
    enabled: ${persistence_enabled}
    accessModes:
      - ${persistence_access_mode}
    size: ${persistence_size}
    storageClass: ${persistence_storage_class}
%{ endif }

  replicas: ${num_replicas}
  resources:
    request:
      cpu: ${request_cpu}
      memory: ${request_mem}
    limits:
      cpu: ${limit_cpu}
      memory: ${limit_mem}

loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1

  %{ if length(schema_configs) > 0 }
  schemaConfig:
    configs: ${schema_configs}
  %{ else }
  schemaConfig:
    configs: []
  %{ endif }

  storage: ${storage}

  limits_config:
%{ for k, v in limits_config ~}
    ${k}: ${v}
%{~ endfor }

  retention_deletes_enabled: true
  retention_period: ${retention_period}

read:
    replicas: 0
write:
  replicas: 0
backend:
  replicas: 0
ingester:
  replicas: 0
querier:
  replicas: 0
queryFrontend:
  replicas: 0
queryScheduler:
  replicas: 0
distributor:
  replicas: 0
compactor:
  replicas: 0
indexGateway:
  replicas: 0
bloomCompactor:
  replicas: 0
bloomGateway:
  replicas: 0
