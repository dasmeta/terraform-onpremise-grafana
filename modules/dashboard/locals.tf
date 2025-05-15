locals {
  dashboard_title = var.name

  # fill dashboard variable options and current required fields
  grafana_templating_list_variables_options_fill = [for variable in var.variables : merge(variable, {
    options = [for option in variable.options : merge(option, { text = coalesce(option.text, option.value) })]
  })]
  grafana_templating_list_variables = [for variable in local.grafana_templating_list_variables_options_fill : merge(variable, {
    current = try(variable.options[index(variable.options.*.selected, true)], null)
  })]


  ## Blocks

  # get all blocks and annotate
  # initial_blocks = list(object({
  #   block = object({type = string}) # "block/sla"
  #   index1 = number
  #   type = string # "sla"
  # }))
  initial_blocks = [
    for index1, block in var.rows : {
      block : block,
      index1 : index1,
      type : replace(block.type, "block/", "")
    } if strcontains(try(block.type, ""), "block/")
  ]

  # annotate each block type with subIndex
  blocks_by_type = { for block_type in distinct([for block in local.initial_blocks : block.type]) :
    block_type => [for index2, block in local.initial_blocks : merge(block, { index2 : index2 }) if strcontains(block.type, block_type)]
  }

  # bring all module results together
  blocks_results = {
    ingress    = values(module.block_ingress).*.result
    service    = values(module.block_service).*.result
    sla        = values(module.block_sla).*.result
    redis      = values(module.block_redis).*.result
    cloudwatch = values(module.block_cloudwatch).*.result
  }

  blocks_by_type_results = concat([], [
    for block_type, type_blocks in local.blocks_by_type : [
      for index3, block in type_blocks : merge(block, { results : local.blocks_results[block.type][index3] }) if contains(keys(local.blocks_results), block.type)
    ] if contains(keys(local.blocks_results), block_type)
  ]...)

  # custom_widgets =

  # blocks_by_type_results_custom_containers = concat(local.blocks_by_type_results, local.custom_widgets)

  # inject block widgets into rows/panels listing in place of block/* definitions
  rows = concat([], [
    for index1, row in var.rows :
    concat(strcontains(try(row.type, ""), "block/") ? [] : [row],
      [
        for item in local.blocks_by_type_results : item.results if item.index1 == index1
    ]...)
  ]...)


  ## Widgets
  # default values from module and provided from outside
  widget_default_values = merge(
    {
      period            = 5 # in minutes
      stat              = "Sum"
      width             = 6
      height            = 5
      expressions       = []
      yAxis             = { left = { min = 0 } }
      datasource        = var.data_source
      container         = "$container"
      deployment        = "$deployment"
      namespace         = "$namespace"
      cluster           = "$cluster"
      region            = null
      anomaly_detection = false
      anomaly_deviation = 6
    },
    var.defaults
  )

  # this will walk through every widget and add row/column + merge with default values
  widget_config_with_raw_column_data_and_defaults = [
    for row_number, row in local.rows : [
      for column_number, column in row : merge(
        local.widget_default_values,
        column,
        {
          row          = row_number,
          column       = column_number,
          row_count    = length(local.rows),
          column_count = length(row)
        }
      )
    ]
  ]

  # groups rows by widget type
  widget_config = { for key, item in flatten(local.widget_config_with_raw_column_data_and_defaults) :
    item.type => merge(
      item,
      # calculate coordinates based on defaults and row/column details
      {
        coordinates = {
          x      = item.column * item.width
          y      = item.row
          width  = item.width
          height = item.height
        }
      }
  )... }

  # combine results (last step)
  widget_result = concat(
    # Container widgets
    values(module.container_cpu_widget).*.data,
    values(module.container_memory_widget).*.data,
    values(module.container_network_widget).*.data,
    values(module.container_restarts_widget).*.data,
    values(module.container_replicas_widget).*.data,
    values(module.container_request_count_widget).*.data,
    values(module.container_response_time_widget).*.data,
    values(module.container_network_traffic_widget).*.data,
    values(module.container_network_transmit_widget).*.data,

    # Pod widgets
    values(module.pod_cpu_widget).*.data,
    values(module.pod_memory_widget).*.data,
    values(module.pod_restarts_widget).*.data,

    # Deployment widgets
    values(module.deployment_replicas_widget).*.data,

    # Ingress widgets
    values(module.ingress_connections_widget).*.data,
    values(module.ingress_request_rate_widget).*.data,
    values(module.ingress_request_count_widget).*.data,
    values(module.ingress_latency_widget).*.data,
    values(module.ingress_cpu_widget).*.data,
    values(module.ingress_memory_widget).*.data,

    # Text widgets
    values(module.text_title).*.data,
    values(module.text_title_with_link).*.data,
    values(module.text_title_with_collapse).*.data,

    # sla/slo/sli widgets
    values(module.widget_sla_slo_sli_main).*.data,
    values(module.widget_sla_slo_sli_latency).*.data,

    # single widgets
    values(module.widget_custom).*.data,

    # Logs widgets
    values(module.logs_count_widget).*.data,
    values(module.logs_error_rate_widget).*.data,
    values(module.logs_warning_rate_widget).*.data,

    # Redis widgets
    values(module.redis_max_uptime_widget).*.data,
    values(module.redis_memory_widget).*.data,
    values(module.redis_total_memory_widget).*.data,
    values(module.redis_cpu_widget).*.data,
    values(module.redis_hits_misses_widget).*.data,
    values(module.redis_restarts_widget).*.data,
    values(module.redis_errors_widget).*.data,
    values(module.redis_clients_widget).*.data,
    values(module.redis_connections_widget).*.data,
    values(module.redis_latency_widget).*.data,
    values(module.redis_network_widget).*.data,
    values(module.redis_replicas_widget).*.data,
    values(module.redis_total_commands_widget).*.data,
    values(module.redis_keys_widget).*.data,
    values(module.redis_expired_evicted_keys_widget).*.data,
    values(module.redis_expiring_notexpiring_keys_widget).*.data,

    # Custom widgets
    values(module.instance_network_widget).*.data,
    values(module.instance_cpu_widget).*.data,
    values(module.instance_disk_widget).*.data

  )
}
