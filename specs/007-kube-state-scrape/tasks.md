# Tasks: kube-state-metrics Annotation-Scrape Fix

- [x] Add a failing native test assertion that kube-state-metrics owns
  `prometheus.io/scrape: "false"` despite conflicting `extra_configs`.
- [x] Add the module-owned Service annotation while retaining the ServiceMonitor.
- [x] Format and run the focused native test.
- [x] Run root validation and inspect the final diff for unintended module or
  interface changes.
- [ ] Release the on-premise module, update the AWS wrapper dependency, then
  update the consumer YAML in a separate release-consumption change.
