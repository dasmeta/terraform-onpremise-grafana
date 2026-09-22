# Minimal live example for Docker Desktop, used to verify the DMVP-10430 disruption-safety change:
# the grafana database no longer renders a PodDisruptionBudget permitting zero evictions.
#
# Only grafana and its created mysql database are enabled. Tempo, loki and prometheus are off because
# none of them is involved in the change and each costs several pods and a volume on a laptop.

module "this" {
  source = "../.."

  grafana = {
    ingress = {
      # nginx is the module default and Docker Desktop's bundled controller serves it. TLS is off because
      # there is no certificate locally, and the module adds a tls block for nginx whenever it is on.
      type        = "nginx"
      tls_enabled = false
      hosts       = ["grafana.localhost"]
    }

    database = {
      # REQUIRED LOCALLY. The default is { "karpenter.sh/capacity-type" = "on-demand" }, which is right on
      # a karpenter cluster and unschedulable here: no Docker Desktop node carries that label, so the mysql
      # pod would sit Pending forever and the change would look like the cause. Setting {} also exercises
      # the documented opt-out.
      node_selector = {}

      persistence = {
        size = "1Gi" # 20Gi by default; the hostpath provisioner will honour either, this is just tidier
      }
    }

    # Laptop-sized. The module default is unset, which lets the chart's own requests apply.
    resources = {
      requests = {
        cpu    = "100m"
        memory = "256Mi"
      }
    }
  }

  tempo      = { enabled = false }
  loki_stack = { enabled = false }
  prometheus = { enabled = false }

  grafana_admin_password = "admin"
}
