# output "dump" {
#   value = {
#     widget_config = local.widget_config
#     widget_result = local.widget_result
#   }
# }

output "blocks_by_type_results" {
  value = local.blocks_by_type_results
}

output "blocks_results" {
  value = local.blocks_results
}

# output "initial_blocks" {
#   value = local.initial_blocks
# }

# output "blocks_by_type" {
#   value = local.blocks_by_type
# }

output "rows" {
  value = local.rows
}

output "widget_config_with_raw_column_data_and_defaults" {
  value = local.widget_config_with_raw_column_data_and_defaults
}

output "widget_config" {
  value = local.widget_config
}

output "widget_result" {
  value = local.widget_result
}
