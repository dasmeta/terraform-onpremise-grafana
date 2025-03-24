terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      version = "> 5.0"
    }
    helm = ">= 2.0"
    kubernetes = {
      version = ">2.3"
    }
    grafana = {
      version = ">= 3.0.0"
      source  = "grafana/grafana"
    }
  }
}
