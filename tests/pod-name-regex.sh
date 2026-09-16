#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_match() {
  local regex=$1
  local value=$2

  [[ "$value" =~ $regex ]] || fail "expected '${value}' to match ${regex}"
}

assert_no_match() {
  local regex=$1
  local value=$2

  [[ ! "$value" =~ $regex ]] || fail "expected '${value}' not to match ${regex}"
}

assert_file_contains() {
  local file=$1
  local expected=$2

  grep -Fq "$expected" "$file" || fail "expected ${file} to contain: ${expected}"
}

deployment_regex='^svc(-(primary|canary))?-[^-]+-[^-]+$'
single_or_deployment_regex='^svc(-(primary|canary))?(-[^-]+)?-[^-]+$'

for pod in svc-7d8f9c4b5d-x2k4p svc-primary-7d8f9c4b5d-x2k4p svc-canary-7d8f9c4b5d-x2k4p; do
  assert_match "$deployment_regex" "$pod"
  assert_match "$single_or_deployment_regex" "$pod"
done

for pod in svc-x2k4p svc-0; do
  assert_match "$single_or_deployment_regex" "$pod"
  assert_no_match "$deployment_regex" "$pod"
done

for pod in svc-worker-6c5d4f-y7z8q svcother-7d8f9c4b5d-x2k4p; do
  assert_no_match "$deployment_regex" "$pod"
  assert_no_match "$single_or_deployment_regex" "$pod"
done

assert_file_contains modules/dashboard/modules/widgets/container/network/base.tf '^${var.container}(-(primary|canary))?-[^-]+-[^-]+$'
assert_file_contains modules/dashboard/modules/widgets/container/replicas/base.tf '^${var.container}(-(primary|canary))?-[^-]+-[^-]+$'
assert_file_contains modules/dashboard/modules/widgets/pod/restarts/base.tf '^${var.pod}(-(primary|canary))?-[^-]+-[^-]+$'
assert_file_contains modules/dashboard/modules/widgets/pod/cpu/base.tf '^${var.pod}(-(primary|canary))?-[^-]+-[^-]+$'
assert_file_contains modules/dashboard/modules/widgets/pod/memory/base.tf '^${var.pod}(-(primary|canary))?-[^-]+-[^-]+$'

assert_file_contains modules/dashboard/modules/widgets/container/network-error/base.tf '^${var.pod}(-(primary|canary))?(-[^-]+)?-[^-]+$'
assert_file_contains modules/dashboard/modules/widgets/container/network-traffic/base.tf '^${var.pod}(-(primary|canary))?(-[^-]+)?-[^-]+$'
assert_file_contains modules/dashboard/modules/alerts/block-service/outputs.tf '^${local.workload_name}(-(primary|canary))?(-[^-]+)?-[^-]+$'
