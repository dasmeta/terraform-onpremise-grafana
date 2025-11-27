module "this" {
  source = "../.."

  application_dashboard = [{
    name = "example-dashboard"
    # alerts = { enabled : false } # allows to disable all auto created alerts
    rows : [
      { type : "block/sla", sla_ingress_type : "nginx", filter = "host!='grafana.localhost'" },
      { type : "block/ingress", filter = "host!='grafana.localhost'" },
      { type : "block/service", name = "http-echo", alerts = { namespaces = ["dev", "prod"] } /* show_err_logs = true */ }, # `show_err_logs = true` is default and it allows to have loki logs widgets on `block/service` block
    ]
    variables = [
      {
        "name" : "namespace",
        "options" : [
          {
            "selected" : true,
            "value" : "dev"
          },
          {
            "value" : "prod"
          }
        ],
      }
    ]
  }]

  grafana = {
    resources = {
      requests = {
        cpu    = "256m"
        memory = "256Mi"
      }
    }
    ingress = {
      type        = "nginx"
      tls_enabled = false
      hosts       = ["grafana.localhost"]
    }
  }

  loki_stack = {
    enabled = true
    loki = { # here we set some tiny cpu/memory/data resources configs for local test env only, in real live environments this options are the common ones which will be used to improve performance of loki
      resources = {
        requests = {
          cpu    = "500m"
          memory = "500Mi"
        }
        limits = {
          cpu    = "2"
          memory = "2500Mi"
        }
      }
      chunksCache = {
        allocatedMemory = 500
      }
      resultsCache = {
        allocatedMemory = 500
      }

      ## this values allow to configure loki chart retention and queries periods, here we have defaults which possibly will be needed to change on dev/prod setups
      # limits_config = {
      #   max_query_length = "7d1h"
      #   retention_period = "360h"
      # }
    }
    promtail = {
      ignored_namespaces = ["kube-system", "monitoring"]
      ignored_containers = ["loki", "manager"]
      extra_pipeline_stages = [ # have transformation stages to handle multiline json logs correctly
        { docker = {} },
        {
          multiline = {
            firstline     = "^\\s*{\\s*$"
            lastline      = "^\\s*}\\s*$"
            max_wait_time = "3s"
          }
        }
      ]
    }
  }

  prometheus = {
    enabled = true
    extra_configs = {
      prometheus-node-exporter = { # we set this block configs to have the prometheus-node-exporter be run ok on Docker Desktop k8s, this is for this test/example only on local Docker Desktop k8s setup
        hostRootFsMount = {
          enabled = false
        }
      }
    }
  }
  grafana_admin_password = "admin"
}

# we deploy same app on two different namespaces: prod and dev
resource "helm_release" "http_echo" {
  for_each = toset(["prod", "dev"])

  name             = "http-echo"
  repository       = "https://dasmeta.github.io/helm"
  chart            = "base"
  namespace        = each.value
  create_namespace = true
  version          = "0.3.15"
  wait             = true

  values = [
    file("${path.module}/http-echo.yaml"),
    <<-EOT
    ingress:
      hosts:
        - host: http-echo.localhost
          paths:
            - path: "/${each.value}"
    EOT
  ]
}
