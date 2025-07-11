variable "pod" {
  type        = string
  default     = "ingress-nginx-controller"
  description = "The name identifier/prefix of nginx ingress controller pods"
}

variable "namespace" {
  type        = string
  default     = "ingress-nginx"
  description = "The namespace where nginx ingress controller is deployed"
}

variable "datasource_uid" {
  nullable    = false
  type        = string
  default     = "prometheus"
  description = "datasource uid for the metrics"
}
