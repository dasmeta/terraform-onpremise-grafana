run "namespace_selector_is_valid_promql" {
  command = apply

  variables {
    namespace = "example"
  }

  assert {
    condition     = output.connector_failed_expr == "sum by (connector) (kafka_connect_connector_state{namespace=\"example\",state=\"failed\"}) > 0"
    error_message = "namespace matcher must sit next to state without a leading comma"
  }

  assert {
    condition     = output.connect_rest_expr == "sum(kafka_connect_rest_up{namespace=\"example\"}) == bool 0"
    error_message = "REST alert must use == bool 0 so Grafana last() > 0 can fire"
  }

  assert {
    condition     = output.exporter_scrape_expr == "(sum by (job) (up{namespace=\"example\"}) == bool 0) or absent(kafka_connect_rest_up{namespace=\"example\"})"
    error_message = "exporter up==0 branch must use == bool 0 so Grafana last() > 0 can fire"
  }
}

run "empty_matchers_do_not_emit_leading_comma" {
  command = apply

  variables {
    namespace = ""
  }

  assert {
    condition     = output.connector_failed_expr == "sum by (connector) (kafka_connect_connector_state{state=\"failed\"}) > 0"
    error_message = "empty matchers must render {state=\"failed\"}, not {,state=\"failed\"}"
  }

  assert {
    condition     = output.task_failed_expr == "sum by (connector, task) (kafka_connect_task_state{state=\"failed\"}) > 0"
    error_message = "empty matchers must not insert a leading comma before state"
  }

  assert {
    condition     = output.connect_rest_expr == "sum(kafka_connect_rest_up) == bool 0"
    error_message = "empty matchers must omit braces on REST queries and use == bool 0"
  }

  assert {
    condition     = output.exporter_scrape_expr == "(sum by (job) (up) == bool 0) or absent(kafka_connect_rest_up)"
    error_message = "empty matchers must not put == 0 on the Grafana-reduced value"
  }

  assert {
    condition     = !strcontains(output.connector_failed_expr, "{,")
    error_message = "failed selector must not start with a comma"
  }
}
