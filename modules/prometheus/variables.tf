variable "namespace" {
  type        = string
  description = "namespace to use for deployment"
  default     = "monitoring"
}

variable "chart_version" {
  type        = string
  description = "prometheus chart version"
  default     = "75.8.0"
}

variable "configs" {
  type = object({
    retention_days = optional(string, "15d")
    storage_class  = optional(string, "gp2")
    storage_size   = optional(string, "100Gi")
    access_modes   = optional(list(string), ["ReadWriteOnce"])
    resources = optional(object({
      request = optional(object({
        cpu = optional(string, "500m")
        mem = optional(string, "500Mi")
      }), {})
      limit = optional(object({
        cpu = optional(string, "1")
        mem = optional(string, "1Gi")
      }), {})
    }), {})
    replicas            = optional(number, 2)
    enable_alertmanager = optional(bool, true)
  })

  description = "Values to send to Prometheus template values file"

  default = {}
}
