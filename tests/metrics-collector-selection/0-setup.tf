terraform {
  # Native terraform test and provider mocking require Terraform >= 1.7.
  # The root module under test remains compatible with its ~> 1.3 constraint.
  required_version = ">= 1.7, < 2.0"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

variable "metrics_collector" {
  type    = string
  default = "prometheus"
}

variable "prometheus_enabled" {
  type    = bool
  default = true
}

variable "victoria_metrics_enabled" {
  type    = bool
  default = true
}

variable "operator_enabled" {
  type    = bool
  default = false
}

variable "operator_chart_version" {
  type    = string
  default = "0.67.2"
}

variable "operator_release_name" {
  type    = string
  default = "victoria-metrics-operator"
}

variable "agent_name" {
  type    = string
  default = "victoria-metrics-agent"
}

variable "agent_replica_count" {
  type    = number
  default = 1
}

variable "node_exporter_enabled" {
  type    = bool
  default = true
}

variable "agent_kubelet_scrape_enabled" {
  type    = bool
  default = true
}

variable "agent_cadvisor_scrape_enabled" {
  type    = bool
  default = true
}

variable "agent_resource_scrape_enabled" {
  type    = bool
  default = false
}
