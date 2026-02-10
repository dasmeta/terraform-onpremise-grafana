terraform {
  required_version = "~> 1.3"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

# to run this example and have helm provider configured with existing k8s cluster set the following env: `export KUBE_CONFIG_PATH=/path/to/eks/cluster.kubeconfig`
provider "helm" {}
