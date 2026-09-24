run "lag_pending_is_15m_even_when_defaults_are_5m" {
  command = apply

  variables {
    cluster_names   = ["example-msk-cluster"]
    consumer_groups = ["example-payments"]
    region          = "eu-central-1"
    defaults = {
      pending_period = "5m"
    }
    alerts = {
      enabled = true
    }
  }

  assert {
    condition     = output.lag_pending_period == "15m"
    error_message = "MaxOffsetLag pending_period must stay 15m when only the shared defaults are 5m"
  }
}

run "lag_pending_can_be_set_on_the_rule" {
  command = apply

  variables {
    cluster_names   = ["example-msk-cluster"]
    consumer_groups = ["example-payments"]
    region          = "eu-central-1"
    defaults = {
      pending_period = "5m"
    }
    alerts = {
      enabled = true
      consumer_lag = {
        pending_period = "30m"
      }
    }
  }

  assert {
    condition     = output.lag_pending_period == "30m"
    error_message = "consumer_lag.pending_period must override the 15m default"
  }
}
