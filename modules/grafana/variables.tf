
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

variable "datasources" {
  type        = list(map(any))
  description = "A list of datasources configurations for grafana."
  default     = []

}

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
      tls_secrets = optional(list(object({
        secret_name = optional(string, "")
        hosts       = optional(list(string), [])
      })), [])
    }), {})

    replicas  = optional(number, 1)
    image_tag = optional(string, "11.4.2")
  })

  description = "Values to construct the values file for Grafana Helm chart"
  default     = {}
}
