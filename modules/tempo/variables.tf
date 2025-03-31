variable "namespace" {
  type        = string
  description = "namespace for tempo deployment"
  default     = "monitoring"
}

variable "region" {
  type        = string
  description = "aws region"
  default     = "eu-central-1"
}

variable "configs" {
  type = object({
    tempo_image_tag          = optional(string, "2.4.0")
    tempo_role_arn           = optional(string, "")
    storage_backend          = optional(string, "s3") # "local" or "s3"
    bucket_name              = optional(string, "")
    enable_metrics_generator = optional(bool, true)
    enable_service_monitor   = optional(bool, true)
    tempo_role_name          = optional(string, "tempo-s3-role")
    oidc_provider_arn        = optional(string, "")

    persistence = optional(object({
      enabled       = optional(bool, true)
      size          = optional(string, "10Gi")
      storage_class = optional(string, "gp2")
    }), {})

    service_account = optional(object({
      name        = optional(string, "tempo-serviceaccount")
      annotations = optional(map(string), {})
    }), {})
  })
}
