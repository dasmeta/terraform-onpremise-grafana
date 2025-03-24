## Usage
To enable some of these alerts for your applications, you just need to replace  `App_1`, `App_2` and `App_3` with the actual names of your applications. You can refer to the Prometheus metrics to identify the available filters that can be used for each application. Additionally, modify the values in the conditions to reflect the real cases of your applications. These adjustments will ensure that the alerts accurately monitor your specific applications and their scaling needs.

## Alert Expressions
Alert expressions are formed based on `metric_name`, `metric_function`, `metric_interval`, and `filters` parameters. They form alert expressions like: `kube_deployment_status_replicas_available{deployment=\"nginx\"}`, `rate(kube_pod_container_status_restarts_total{container=\"nginx\"}[5m])`, but sometimes we need to have more complex queries like this one: `sum(rate(nginx_ingress_controller_requests{status=~'5..'}[1m])) by (ingress,cluster) / sum(rate(nginx_ingress_controller_requests[1m])) by (ingress) * 100 > 5`.
When you want to create simple queries, use the parameters counted above. And when you need to create complex queries, don't pass those parameters; instead, pass the query string to the `expr` variable. Check the `tests/expressions` folder for an example with complex queries."

## Conditions and Thresholds
Alert conditions are formed based on $B blocks and `equation`, `threshold` parameters users pass to the module.
`equation` parameter can only get these values:
- `lt` corresponds to `<`
- `gt` corresponds to `>`
- `e` corresponds to `=`
- `lte` corresponds to `<=`
- `gte` corresponds to `>=`

And `threshold` parameter is the number value against which B blocks are compared in the math expression.

## Priority
Specify alert rule priority by passing the priority parameter to the alert_rules variable. By default, the value will be P2. For example, you can set the value to P1 and configure it so that alerts with P1 priority will be sent to Opsgenie, while the other alerts will be sent to Slack.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 1.40.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_grafana"></a> [grafana](#provider\_grafana) | >= 1.40.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [grafana_folder.rule_folder](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/folder) | resource |
| [grafana_rule_group.this](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/rule_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_interval_seconds"></a> [alert\_interval\_seconds](#input\_alert\_interval\_seconds) | The interval, in seconds, at which all rules in the group are evaluated. If a group contains many rules, the rules are evaluated sequentially. | `number` | `10` | no |
| <a name="input_alert_rules"></a> [alert\_rules](#input\_alert\_rules) | This varibale describes alert folders, groups and rules. | <pre>list(object({<br/>    name                 = string                                    # The name of the alert rule<br/>    no_data_state        = optional(string, "NoData")                # Describes what state to enter when the rule's query returns No Data<br/>    exec_err_state       = optional(string, "Error")                 # Describes what state to enter when the rule's query is invalid and the rule cannot be executed<br/>    summary              = optional(string, null)                    # Rule annotation as a summary, if not passed automatically generated based on data<br/>    labels               = optional(map(any), { "priority" : "P1" }) # Labels help to define matchers in notification policy to control where to send each alert<br/>    folder_name          = optional(string, "Main Alerts")           # Grafana folder name in which the rule will be created<br/>    datasource           = string                                    # Name of the datasource used for the alert<br/>    expr                 = optional(string, null)                    # Full expression for the alert<br/>    metric_name          = optional(string, "")                      # Prometheus metric name which queries the data for the alert<br/>    metric_function      = optional(string, "")                      # Prometheus function used with metric for queries, like rate, sum etc.<br/>    metric_interval      = optional(string, "")                      # The time interval with using functions like rate<br/>    settings_mode        = optional(string, "replaceNN")             # The mode used in B block, possible values are Strict, replaceNN, dropNN<br/>    settings_replaceWith = optional(number, 0)                       # The value by which NaN results of the query will be replaced<br/>    filters              = optional(any, null)                       # Filters object to identify each service for alerting<br/>    function             = optional(string, "mean")                  # One of Reduce functions which will be used in B block for alerting<br/>    equation             = string                                    # The equation in the math expression which compares B blocks value with a number and generates an alert if needed. Possible values: gt, lt, gte, lte, e<br/>    threshold            = number                                    # The value against which B blocks are compared in the math expression<br/>  }))</pre> | `[]` | no |
| <a name="input_disable_provenance"></a> [disable\_provenance](#input\_disable\_provenance) | Allow modifying the rule groups from other sources than Terraform or the Grafana API. | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
