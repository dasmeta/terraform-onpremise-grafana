terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 1.40.0"
    }
  }

  required_version = ">= 1.3.0"
}
