
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
  pathType: ${ingress_path_type}

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
%{~ if prometheus_enable }
      - name: Prometheus
        type: prometheus
        access: proxy
        url: ${prometheus_url}
        isDefault: true
        editable: true
%{~ endif ~}
%{~ if cloudwatch_enable }
      - name: CloudWatch
        type: cloudwatch
        access: proxy
        uid: cloudwatch
        editable: false
        jsonData:
          authType: default
          assumeRoleArn: ${cloudwatch_role_arn}
          defaultRegion: ${aws_region}
%{~ endif ~}

replicas: ${replicas}
image:
  tag: ${image_tag}

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
