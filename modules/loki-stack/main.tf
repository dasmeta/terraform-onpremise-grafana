resource "helm_release" "loki" {
  chart            = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  name             = var.configs.loki.release_name
  namespace        = var.namespace
  create_namespace = var.create_namespace
  version          = var.configs.loki.chart_version
  timeout          = 600

  values = [
    jsonencode(var.configs.loki.deploymentMode == "SingleBinary" ? {
      singleBinary = {
        persistence = var.configs.loki.persistence
        replicas    = var.configs.loki.replicas
        resources   = var.configs.loki.resources
      }
    } : {}),
    jsonencode(
      {
        deploymentMode = var.configs.loki.deploymentMode
        serviceAccount = var.configs.loki.serviceAccount
        monitoring     = var.configs.loki.monitoring
        loki = {
          structuredConfig = var.configs.loki.structuredConfig
          commonConfig     = var.configs.loki.commonConfig
          auth_enabled     = var.configs.loki.auth_enabled
          limits_config    = var.configs.loki.limits_config
          storage          = var.configs.loki.storage
          compactor        = var.configs.loki.compactor_options
          schemaConfig = {
            configs = var.configs.loki.schemaConfig
          }
        }
        gateway = {
          enabled = var.configs.loki.ingress.enabled
          ingress = {
            enabled          = var.configs.loki.ingress.enabled
            ingressClassName = var.configs.loki.ingress.type
            annotations      = local.ingress_annotations
            hosts = [for host in var.configs.loki.ingress.hosts : {
              host  = host
              paths = [{ path = var.configs.loki.ingress.path, pathType = var.configs.loki.ingress.path_type }]
            }]
            tls = [for item in local.ingress_tls : {
              secretName = item.secret_name
              hosts      = var.configs.loki.ingress.hosts
            }]
          }
        }
        chunksCache    = var.configs.loki.chunksCache
        resultsCache   = var.configs.loki.resultsCache
        test           = var.configs.loki.test
        lokiCanary     = var.configs.loki.lokiCanary
        ruler          = var.configs.loki.ruler
        compactor      = var.configs.loki.compactor
        read           = var.configs.loki.read
        write          = var.configs.loki.write
        backend        = var.configs.loki.backend
        ingester       = var.configs.loki.ingester
        querier        = var.configs.loki.querier
        queryFrontend  = var.configs.loki.queryFrontend
        queryScheduler = var.configs.loki.queryScheduler
        distributor    = var.configs.loki.distributor
        indexGateway   = var.configs.loki.indexGateway
        bloomBuilder   = var.configs.loki.bloomBuilder
        bloomPlanner   = var.configs.loki.bloomPlanner
        bloomGateway   = var.configs.loki.bloomGateway
    }),
    jsonencode(var.configs.loki.extra_configs)
  ]
}

# TODO: the promtail deprecated, consider to have this replaced with for example fluent/fluent-bit
resource "helm_release" "promtail" {
  count = var.configs.promtail.enabled ? 1 : 0

  chart            = "promtail"
  repository       = "https://grafana.github.io/helm-charts"
  name             = "${var.configs.loki.release_name}-promtail"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  version          = var.configs.promtail.chart_version
  timeout          = 300

  values = [
    templatefile("${path.module}/values/promtail-values.tpl", {
      promtail_log_level                = var.configs.promtail.log_level
      log_format                        = var.configs.promtail.log_format
      promtail_extra_scrape_configs     = local.extra_scrape_configs_yaml
      promtail_extra_label_configs_yaml = local.extra_relabel_configs_yaml
      promtail_extra_label_configs_raw  = local.extra_relabel_configs
      promtail_extra_pipeline_stages    = local.extra_pipeline_stages_yaml
      promtail_clients                  = try(var.configs.promtails.clients, ["http://${var.configs.loki.release_name}:3100/loki/api/v1/push"])
      promtail_server_port              = var.configs.promtail.server_port
      }
    ),
    jsonencode(var.configs.promtail.extra_configs)
  ]
}

resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}
