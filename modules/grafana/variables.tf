
variable "namespace" {
  type        = string
  description = "namespace to use for deployment"
  default     = "monitoring"
}

variable "grafana_admin_password" {
  type        = string
  description = "admin password"
  default     = ""
}

variable "chart_version" {
  type        = string
  description = "grafana chart version"
  default     = "8.11.1"
}

variable "prometheus_datasource" {
  type = object({
    enabled = optional(bool, true)
    url     = optional(string, "http://prometheus-operated.monitoring.svc.cluster.local:9090")
  })
  description = "Enable Prometheus as a Grafana data source"
  default     = {}
}

variable "cloudwatch_datasource" {
  type = object({
    enabled             = optional(bool, false)
    cloudwatch_role_arn = optional(string, "")
    aws_region          = optional(string, "eu_central_1")
  })
  description = "Enable Cloudwatch as a Grafana data source"
  default     = {}
}

variable "tempo_datasource" {
  type = object({
    enabled = optional(bool, false)
    url     = optional(string, "http://tempo.tempo.svc.cluster.local:3200")
  })
  description = "Enable Tempo as a Grafana data source"
  default     = {}
}

variable "loki_datasource" {
  type = object({
    enabled = optional(bool, false)
    url     = optional(string, "http://loki.loki.svc.cluster.local:3100")
  })
  description = "Enable Loki as a Grafana data source"
  default     = {}
}

# variable "aws_region" {
#   type    = string
#   default = "eu-central-1"
# }

variable "configs" {
  type = object({
    resources = optional(object({
      request = optional(object({
        cpu = optional(string, "1")
        mem = optional(string, "2Gi")
      }), {})
      limit = optional(object({
        cpu = optional(string, "2")
        mem = optional(string, "3Gi")
      }), {})
    }), {})
    persistence = optional(object({
      enabled = optional(bool, true)
      type    = optional(string, "pvc")
      size    = optional(string, "10Gi")
    }), {})
    ingress_configs = optional(object({
      annotations = optional(map(string),
        {
          "kubernetes.io/ingress.class"                = "alb"
          "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"      = "ip"
          "alb.ingress.kubernetes.io/listen-ports"     = "[{\\\"HTTP\\\": 80}]"
          "alb.ingress.kubernetes.io/group.name"       = "monitoring"
          "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
        }
      )
      hosts     = optional(list(string), ["grafana.example.com"])
      path      = optional(string, "/")
      path_type = optional(string, "Prefix")
    }), {})

    replicas  = optional(number, 1)
    image_tag = optional(string, "11.4.2")
  })

  description = "Values to construct the values file for Grafana Helm chart"
  default     = {}
}

variable "additional_data_sources" {
  type        = map(any)
  description = "Any additional grafana datasources to merge in"
  default     = {}
}
