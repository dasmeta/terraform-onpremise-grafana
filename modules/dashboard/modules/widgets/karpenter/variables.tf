variable "panel" {
  type        = string
  description = "The karpenter panel to render, one of the keys in local.panels (for example `drift-duration`)"

  validation {
    condition = contains([
      "nodes", "drifted-nodes", "drift-duration", "nodes-created-terminated", "nodes-not-initialized", "nodes-disrupted",
      "disruption-decisions", "interruptions", "cloudprovider-errors", "nodepool-usage", "pending-pods", "pod-wait", "reconcile-errors"
    ], var.panel)
    error_message = "Unknown karpenter panel."
  }
}

variable "namespace" {
  nullable    = false
  type        = string
  default     = "karpenter"
  description = "The namespace where karpenter controller runs, karpenter metrics get this namespace label from the scrape target"
}

variable "extra_filters" {
  nullable    = false
  type        = string
  default     = ""
  description = "Additional PromQL label matchers appended to every query, for example `job=\"karpenter\"`"
}

variable "datasource_uid" {
  nullable    = false
  type        = string
  default     = "prometheus"
  description = "Prometheus datasource UID"
}

variable "coordinates" {
  type = object({
    x : number
    y : number
    width : number
    height : number
  })
  description = "Panel coordinates"
}

variable "period" {
  nullable    = false
  type        = string
  default     = "$__rate_interval"
  description = "Prometheus range interval used by rate/increase queries"
}
