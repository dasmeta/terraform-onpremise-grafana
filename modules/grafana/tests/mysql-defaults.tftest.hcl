run "default_mysql_values_protect_primary_from_voluntary_disruption" {
  command = plan

  variables {
    grafana_admin_password = "test-admin-password"
  }

  assert {
    condition     = jsondecode(helm_release.mysql[0].values[1]).primary.podAnnotations["karpenter.sh/do-not-disrupt"] == "true"
    error_message = "Grafana MySQL primary pod must default karpenter.sh/do-not-disrupt to true."
  }

  assert {
    condition     = jsondecode(helm_release.mysql[0].values[1]).primary.pdb.minAvailable == 1
    error_message = "Grafana MySQL primary PDB must default minAvailable to 1."
  }

  assert {
    condition     = jsondecode(helm_release.mysql[0].values[1]).primary.pdb.maxUnavailable == ""
    error_message = "Grafana MySQL primary PDB must default maxUnavailable to an empty value."
  }
}
