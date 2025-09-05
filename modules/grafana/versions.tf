terraform {
  required_version = ">= 1.3.0"
  required_providers {
    helm = ">= 2.0"
    kubernetes = {
      version = ">2.3"
    }
    grafana = {
      version = ">= 4.0.0"
      source  = "grafana/grafana"
    }
  }
}
