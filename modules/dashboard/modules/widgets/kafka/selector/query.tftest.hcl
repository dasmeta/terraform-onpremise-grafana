run "empty_matchers_render_no_selector" {
  command = apply

  variables {
    namespace     = ""
    extra_filters = ""
    cluster_label = ""
    cluster       = ""
  }

  assert {
    condition     = length(output.matchers) == 0
    error_message = "empty matchers must be an empty list"
  }

  assert {
    condition     = output.selector == ""
    error_message = "empty matchers must render an empty selector, not braces or a leading comma"
  }
}

run "namespace_renders_single_matcher" {
  command = apply

  variables {
    namespace = "example"
  }

  assert {
    condition     = output.selector == "{namespace=\"example\"}"
    error_message = "namespace matcher must render a single-label selector"
  }
}
