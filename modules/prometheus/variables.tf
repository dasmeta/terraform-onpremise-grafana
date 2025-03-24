variable "namespace" {
  type        = string
  description = "namespace to use for deployment"
  default     = "monitoring"
}

variable "configs" {
  type = object({
    retention_days = optional(string, "15d")
    storage_class  = optional(string, "efs-sc-root")
    storage_size   = optional(string, "10Gi")
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
    enable_alertmanager = optional(bool, true)
  })

  description = "Values to send to Prometheus template values file"

  default = {}
}
