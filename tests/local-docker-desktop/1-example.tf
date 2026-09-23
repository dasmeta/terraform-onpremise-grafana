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
      # No node_selector set: the default is empty, which is what a cluster without karpenter needs. On EKS
      # you would pin this to on-demand capacity -- see the variable description.
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

  # The default disk-capacity alert resolves its folder to "application-dashboard" and then LOOKS IT UP
  # with a data source. That folder only exists if an application_dashboard created it, and there are none
  # here -- so the apply fails on a folder nothing was ever asked to create. Pre-existing module coupling,
  # not related to what this example tests.
  alerts = {
    disk_capacity = { enabled = false }
  }

  tempo      = { enabled = false }
  loki_stack = { enabled = false }
  prometheus = { enabled = false }

  grafana_admin_password = "admin"
}

# Opt-in check for the annotation: uncomment, re-plan, and the mysql pod should carry
# karpenter.sh/do-not-disrupt again. Left commented because the default is what we want verified.
# (set database.do_not_disrupt = true inside the grafana block above)
