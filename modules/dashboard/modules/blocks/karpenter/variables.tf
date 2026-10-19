variable "namespace" {
  nullable    = false
  type        = string
  default     = "karpenter"
  description = "The namespace where karpenter controller runs, karpenter metrics get this namespace label from the scrape target so it is used to select karpenter metrics"
}

variable "extra_filters" {
  nullable    = false
  type        = string
  default     = ""
  description = "Additional PromQL label matchers appended to every karpenter query, for example `job=\"karpenter\"` or `cluster=\"prod\"`"
}

variable "datasource_uid" {
  nullable    = false
  type        = string
  default     = "prometheus"
  description = "Prometheus datasource UID"
}

variable "period" {
  nullable    = false
  type        = string
  default     = "$__rate_interval"
  description = "Prometheus range interval used by rate/increase panels"
}

variable "columns" {
  nullable    = false
  type        = number
  default     = 3
  description = "The number of widgets to place in each line"
}

variable "block_name" {
  nullable    = false
  type        = string
  default     = "Karpenter"
  description = "Dashboard block title"
}

variable "widgets" {
  type = object({
    nodes          = optional(bool, true)  # nodes per nodepool/capacity type, nodes created/terminated, nodes not initialized
    drift          = optional(bool, true)  # drifted nodes count and how long each node is in drifted state
    disruption     = optional(bool, true)  # nodes disrupted by reason and disruption decisions
    capacity       = optional(bool, true)  # pods waiting for capacity, longest pod wait per phase(decision, node launch) and nodepool usage against its limits
    cloud_provider = optional(bool, true)  # cloud provider call errors (Create means node launch), available with every karpenter cloud provider
    controller     = optional(bool, true)  # karpenter controller reconcile errors
    interruption   = optional(bool, false) # interruption messages received/handled, only karpenter providers with an interruption queue (AWS SQS) expose these metrics, so it is opt-in
  })
  default     = {}
  description = "Allows to enable/disable karpenter block widget groups"
}
