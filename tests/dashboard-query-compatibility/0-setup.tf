terraform {
  # Native terraform test and provider mocking require Terraform >= 1.7.
  # The production module remains compatible with Terraform ~> 1.3.
  required_version = ">= 1.7, < 2.0"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
