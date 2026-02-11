terraform {
  required_version = "~> 1.3"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    deepmerge = {
      source  = "isometry/deepmerge"
      version = "~> 1.1"
    }
  }
}

# to customize the grafana hostname, scheme, and admin password set the following env: `export TF_VAR_grafana_hostname=your_grafana_hostname`, `export TF_VAR_grafana_scheme=https`, and `export TF_VAR_grafana_admin_password=your_grafana_admin_password`
variable "grafana_scheme" {
  type        = string
  description = "Grafana URL scheme (http or https)"
  default     = "http"
}

variable "grafana_hostname" {
  type        = string
  description = "Grafana hostname for ingress and provider URL"
  default     = "grafana.localhost"
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password"
  default     = "admin"
  sensitive   = true
}

# it is supposed to have docker desktop with kubernetes enabled, so that grafana will be created and provider will be able to connect to it
provider "grafana" {
  url                  = "${var.grafana_scheme}://${var.grafana_hostname}"
  auth                 = "admin:${var.grafana_admin_password}"
  insecure_skip_verify = var.grafana_scheme == "http" # Skip TLS verification for HTTP, verify for HTTPS
}

# to run this example and have helm provider configured with existing k8s cluster set the following env: `export KUBE_CONFIG_PATH=/path/to/eks/cluster.kubeconfig`
provider "helm" {}


# # metric server, cadvisor and nginx needed to be installed, here are helm/kubectl install commands on how this services can be deployed on Docker Desktop k8s if missing
# ```sh

# ## add repos
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
# helm repo add ckotzbauer https://ckotzbauer.github.io/helm-charts

# ## nginx
# kubectl create ns ingress-nginx
# helm diff upgrade --install ingress-nginx ingress-nginx/ingress-nginx --version 4.14.0 --namespace ingress-nginx --set controller.metrics.enabled=true --set controller.podAnnotations."prometheus\.io/scrape"=true --set controller.podAnnotations."prometheus\.io/port"=10254

# ## metrics-server
# helm diff upgrade --install metrics-server metrics-server/metrics-server --version 3.13.0 --namespace kube-system --set args.0="--kubelet-insecure-tls"

## cadvisor (install after grafana-stack install as this needs prometheus ServiceMonitor crds)
# helm diff upgrade --install cadvisor ckotzbauer/cadvisor --version 2.4.1 --namespace kube-system --set containerRuntime=containerd --set service.enabled=true --set service.port=8080 --set metrics.enabled=true --set metrics.interval=30s --set metrics.scrapeTimeout=30s \
# --set-json 'metrics.metricRelabelings=[
#   {"action":"replace","sourceLabels":["container_label_io_kubernetes_container_name"],"targetLabel":"container","regex":"(.+)","replacement":"$1"},
#   {"action":"replace","sourceLabels":["container_label_io_kubernetes_pod_name"],"targetLabel":"pod","regex":"(.+)","replacement":"$1"},
#   {"action":"replace","sourceLabels":["container_label_io_kubernetes_pod_namespace"],"targetLabel":"namespace","regex":"(.+)","replacement":"$1"},
#   {"action":"keep","sourceLabels":["__name__","id"],"regex":"container_.+;/kubepods(.slice)?/.+"},
#   {"action":"drop","sourceLabels":["container","__name__"],"regex":"POD;(container_(cpu|memory|fs|blkio|tasks).+)"},
#   {"action":"drop","sourceLabels":["container_label_io_kubernetes_docker_type","__name__"],"regex":"podsandbox;(container_(cpu|memory|fs|blkio|tasks).+)"}
# ]'
# ```
