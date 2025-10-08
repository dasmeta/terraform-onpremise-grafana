terraform {
  required_version = ">= 1.8.0"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# there is need to have grafana running and available by provider url and auth
provider "grafana" {
  url  = "https://grafana.dev.trysela.com"
  auth = "admin:adminPass321"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/sela-dev-eks-dev"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/sela-dev-eks-dev"
}

provider "aws" {
  region = "us-east-2"
}
