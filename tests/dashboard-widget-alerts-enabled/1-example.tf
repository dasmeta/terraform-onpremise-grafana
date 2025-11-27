module "this" {
  source = "../.."

  grafana_admin_password = "admin"
  application_dashboard = [{
    name = "first-dashboard"
    alerts = {
      enabled = false
    }
    rows : [
      { type : "block/sla", sla_ingress_type : "nginx", # no additional configs needed for sla block based on nginx ingress
        # alerts : { defaults : { metric_filter : "host!~'grafana.+'" } } # filter out grafana domain requests from nginx alerts(in real setup this also can be handy to have)
      },
      { type : "block/ingress" # the ingress nginx also being considered as service and it got service alerts also
        # alerts : { defaults : { metric_filter : "host!~'grafana.+'" } } # filter out grafana domain requests from nginx alerts(in real setup this also can be handy to have)
      },
      { type : "block/service", name : "basic-service", namespace : "prod" },                                                                                # by default no additional configs needed beside "namespace" to get alerts enabled
      { type : "block/service", name : "with-canary-service", namespace : "prod", alerts : { defaults : { workload_suffix : "-primary" } } },                # flagger canary alters deployment and adds "primary" suffix
      { type : "block/service", name : "one-replica-or-exact-replicas-service", namespace : "prod", alerts : { replicas_max : { enabled : false } } },       # disable max replica alert as we have just one only replica
      { type : "block/service", name : "cronjob-service", namespace : "prod", alerts : { defaults : { workload_type : "cronjob" } } },                       # cronjob/cron type service alerts configs
      { type : "block/service", name : "in-multiple-namespaces--same-service", namespace : "prod", alerts : { namespaces : ["namespace1", "namespace2"] } }, # create alerts for multiple namespaces
      { type : "block/service", name : "no-cpu-memory-request-limits-set-service", namespace : "prod", alerts : {                                            # set cpu(cores)/memory(megabytes) resources readline manually, can be used if no request/limit set, by default it uses pod cpu/memory resources value set
        cpu : { threshold : 0.256 }, memory : { threshold : 128 }
      } },
      { type : "block/service", name : "only-cpu-memory-request-set-service", namespace : "prod", alerts : { # set cpu/memory alerts to be based on this resources requests instead of limits, can be used when limits are not set but requests are set, by default it uses pod cpu/memory resources limits values
        cpu : { threshold_resource : "requests" }, memory : { threshold_resource : "requests" },
        replicas_no : {
          exec_err_state : "OK"
        },
        replicas_min : {
          exec_err_state : "OK"
        },
        replicas_max : {
          exec_err_state : "OK"
        },
      } },
      { type : "block/service", name : "all-possible-alert-options", namespace : "prod", alerts : { # here we have service block alerts all possible configs with defaults and descriptions
        defaults : {
          enabled : true                 # whether by default block widget alerts are enabled, it allows to disable alert by default and enable for specific widget only
          workload_type : "deployment"   # the workload type of app setup, can be "daemonset", "deployment", "statefulset" and "cronjob"
          workload_suffix : ""           # allows to filter workload or pod via {var.name}{var.defaults.workload_suffix} filtration, can be used for example in case we have flagger canary deployment to add "-primary" suffix to filter deployment
          workload_prefix : ""           # allows to filter workload or pod via {var.defaults.workload_suffix}{var.name} filtration, can be used for example in case we have a deployment which name differs from container name with custom suffix like in nginx ingress container named "controller" and daemonset named "ingress-nginx-controller"
          labels : { "priority" : "P2" } # the service level monitoring alarms generally are considered as P2 priority and desired to be sent to slack channel)
          pending_period : "1m"          # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire)
          interval : "5m"                # the time interval to use to evaluate/aggregate/rate metric for comparison
          deviation : 10                 # the deviation threshold to consider increase/decrease of metric as anomaly and fire alert, we use this now for network alert (in this case 10 means that the metric got increased x10 times withing provided interval)
          threshold_percent : 99         # the percent threshold to use when triggering alerts on resources like cpu/memory
          exec_err_state : "OK"
          no_data_state : "NoData" # define how to handle if no data for query, by default it will fire alert with no data info          group : null                   # grafana alert group name which used for grouping, if null the group name will be based on service name/namespace in format `Service {namespace}/{name}`
        }

        replicas_no : {
          enabled : null                 # whether to have alert if no any replica/pod available
          pending_period : "0s"          # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
          labels : { "priority" : "P1" } # define alert labels to filter in notification policies, this extends with override the defaults labels. we set here P1 priority as if there are no any pods the service is down
          no_data_state : null           # define how to handle if no data for query, if set `null` here it takes  defaults value
          exec_err_state : "OK"
          annotations : {
            "impact" : "Service will go down, maybe it is just a test..."
          } # define alert annotations to filter in notification policies, this extends with override the defaults annotations          group : null                   # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
        }
        replicas_min : {
          enabled : null        # whether to have alert on min replicas/pods, so that if there are no at least min count of pods/replicas it will trigger alert
          pending_period : null # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
          threshold : null      # for manually set min replica count, if not specified it will automatically get this based on hpa min, recommended to not set this if hpa is enabled, but if prometheus horizontalpodautoscaler metrics are not enable there may be need to set this manually
          no_data_state : "OK"  # define how to handle if no data for query, if set `null` here it takes  defaults value
          annotations : {
            "impact" : "Service will go down, maybe it is just a test..."
          }            # define alert annotations to filter in notification policies, this extends with override the defaults annotations          labels : {}           # define alert labels to filter in notification policies, if set `null` here it takes defaults labels.
          group : null # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
        }
        replicas_max = {
          enabled : null        # whether to have alert on max replicas/pods, so that if it reached to max count of pods/replicas it will trigger alert
          pending_period : null # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
          threshold : null      # for manually set max replica count, if not specified it will automatically get this based on hpa min, recommended to not set this if hpa is enabled, but if prometheus horizontalpodautoscaler metrics are not enable there may be need to set this manually
          no_data_state : "OK"  # define how to handle if no data for query, if set `null` here it takes  defaults value
          labels : {}           # define alert labels to filter in notification policies, this extends with override the defaults labels
          group : null          # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
        }
        replicas_state : {
          enabled : null        # whether to have alert on Failed/Pending/Unknown status/phase replicas/pods, so that if it already long time there pods on those phase we get notified
          pending_period : null # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
          threshold : 1         # the min count of replicas/pods with Failed/Pending/Unknown status/phase to trigger alert
          no_data_state : "OK"  # define how to handle if no data for query, if set `null` here it takes  defaults value
          labels : {}           # define alert labels to filter in notification policies, this extends with override the defaults labels
          group : null          # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
        }
        job_failed = {
          enabled : false       # whether to have alert on job/cronjob failed status, we have this alert disabled by default as it is only job/cronjob related
          pending_period : null # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
          threshold : 1         # the min count of failed jobs to trigger alert
          no_data_state : null  # define how to handle if no data for query, if set `null` here it takes  defaults value
          labels : {}           # define alert labels to filter in notification policies, this extends with override the defaults labels
          group : null          # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
        }
        restarts = {           # configure service pod/container restart based alert
          enabled : null       # whether the restart based alert is enabled
          interval : null      # the time interval used to evaluate/aggregate restart count, if set `null` here it takes  defaults value
          threshold : 3        # the count of restarts that it will consider as read line to fire alert if exceeded
          no_data_state : null # define how to handle if no data for query, if set `null` here it takes  defaults value
          labels : {}          # define alert labels to filter in notification policies, this extends with override the defaults labels
          group : null         # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
        }
        network_in = {          # to configure network in/out traffic anomaly increase alerting
          enabled : null        # wether to create alert on network in/receive anomaly increase/decrease of traffic
          pending_period : null # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
          interval : null       # the time interval to use to evaluate/aggregate/rate network avg traffic to compare with previous same interval value, if set `null` here it takes  defaults value
          deviation : null      # the threshold to consider increase/decrease of traffic as anomaly and fire alert (in this case 10 means that the traffic got increased x10 times withing provided interval)
          no_data_state : null  # define how to handle if no data for query, if set `null` here it takes  defaults value
          labels : {}           # define alert labels to filter in notification policies, this extends with override the defaults labels
          group : null          # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
        }
        network_out = {         # to configure network in/out traffic anomaly increase alerting
          enabled : null        # wether to create alert on network out/transmit anomaly increase/decrease of traffic
          pending_period : null # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
          interval : null       # the time interval to use to evaluate/aggregate/rate network avg traffic to compare with previous same interval value, if set `null` here it takes  defaults value
          deviation : null      # the threshold to consider increase/decrease of traffic as anomaly and fire alert (in this case 10 means that the traffic got increased x10 times withing provided interval)
          no_data_state : null  # define how to handle if no data for query, if set `null` here it takes  defaults value
          labels : {}           # define alert labels to filter in notification policies, this extends with override the defaults labels
          group : null          # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
        }
        cpu = {                         # to configure cpu/memory overload based alerting
          enabled : null                # whether cpu high load based alerting is enabled
          pending_period : null         # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
          interval : null               # the time interval to use to evaluate/aggregate/rate network avg traffic to compare with previous same interval value, if set `null` here it takes  defaults value
          threshold_percent : null      # the read line percent to trigger alert of cpu/memory resource usage exceeded, if set `null` here it takes  defaults threshold_percent value
          threshold_resource : "limits" # the read line limit metric to use, allowed values are "limits" or "requests"
          threshold : null              # the read line limit in number of cores(0.256 means 256m) to calculate threshold_percent against, by default it uses deployment limit for this but in case no limit set this can be used to configure custom limit for alert
          no_data_state : null          # define how to handle if no data for query, if set `null` here it takes  defaults value
          labels : {}                   # define alert labels to filter in notification policies, this extends with override the defaults labels
          group : null                  # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
        }
        memory = {                      # to configure cpu/memory overload based alerting
          enabled : null                # whether cpu high load based alerting is enabled
          pending_period : null         # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
          threshold_percent : null      # the read line percent to trigger alert of cpu/memory resource usage exceeded, if set `null` here it takes  defaults threshold_percent value
          threshold_resource : "limits" # the read line limit metric to use, allowed values are "limits" or "requests"
          threshold : null              # the read line limit in megabytes to calculate threshold_percent against, by default it uses deployment limit for this but in case no limit set this can be used to configure custom limit for alert
          no_data_state : null          # define how to handle if no data for query, if set `null` here it takes  defaults value
          labels : {}                   # define alert labels to filter in notification policies, this extends with override the defaults labels
          group : null                  # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
        }
      } },
    ]

    ## the additional configs that can be handy to set for alerting
    # data_source : {
    #   uid : "prometheus" # allows to set/change default "prometheus" named datasource which dashboard/alert objects will use as default if no specific(widget level) set
    # }
    # alerts : { # block/widget alerts common configs control(NOTE: that this is optional block and generally no need for this)
    #   enabled : false        # can be used to disable all alerts
    #   defaults : {           # allows to set some general default for all alerts
    #     no_data_state : "OK" # when initially deploying dashboard with alerts consider setting no data state to "OK" globally to no get lot of alerts, and after fixing no data state having alert and setting exactly where it is supposed to be set you can remove this config to have no alert state also handled as issue
    #   }
    # }

  }]

  ## the alerts separate block being used to configure channels(contact points), notification tag=>channel routing and custom alert rules
  alerts = {
    contact_points = {
      slack = [
        {
          name        = "slack"
          webhook_url = "https://hooks.slack.com/services/xxxx/yyyyyy/zzzzzzzz" # secret value
        }
      ]
      ## to enable opsgenie contact point
      # opsgenie = [
      #   {
      #     name       = "OpsGenie"
      #     api_key    = "{opsgenie-integration-api-key}" # secret value
      #     auto_close = true
      #   }
      # ]
    }
    notifications = {
      contact_point   = "slack" # default contact point
      group_interval  = "1m"    # for testing we set this low values, in real setup remove this line to use default
      repeat_interval = "1m"    # for testing we set this low values, in real setup remove this line to use default

      ## to sent all alerts to slack and only P1 priority alerts to opsgenie
      # policies = [
      #   {
      #     contact_point = "opsgenie"
      #     matchers      = [{ label = "priority", match = "=", value = "P1" }]
      #   },
      #   {
      #     contact_point = "slack"
      #   }
      # ]
    }
    rules = [ # to create extra custom alerts beside dashboard widget block attached ones
      {
        "datasource" : "prometheus",
        "equation" : "gt",
        "expr" : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
        "function" : "mean",
        "name" : "Latency P1",
        "labels" : {
          "priority" : "P1",
        }
        filters : {}
        "threshold" : 3

        # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
        "no_data_state" : "OK"
        # "exec_err_state" : "OK"
        # "exec_err_state" : "Alerting" # uncomment to trigger new alert
      },
      {
        "datasource" : "prometheus",
        "equation" : "gt",
        "expr" : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
        "function" : "mean",
        "name" : "Latency P2",
        "labels" : {
          "priority" : "P2",
        }
        filters : {}
        "threshold" : 3

        # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
        "no_data_state" : "OK"
        # "exec_err_state" : "OK"
        # "exec_err_state" : "Alerting" # uncomment to trigger new alert
      }
    ]
  }

  # for this test/example we disable all other components
  grafana = {
    resources = {
      requests = {
        cpu    = "1"
        memory = "1Gi"
      }
    }
    ingress = {
      type        = "alb"
      tls_enabled = true
      public      = true

      hosts = ["grafana.example.com"]
      annotations = {
        "alb.ingress.kubernetes.io/certificate-arn" = "cert_arn",
        "alb.ingress.kubernetes.io/group.name"      = "dev-ingress"
      }
    }
    trace_log_mapping = {
      enabled = true
    }

  }

  tempo = {
    enabled = false
  }

  loki_stack = {
    enabled = false
  }

  prometheus = {
    enabled = true
  }
}
