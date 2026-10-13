# Implementation plan

1. Add an optional `is_paused` default to generated service alerts.
2. Add the value to each generated rule object at the block-service output boundary.
3. Extend the generic rule input and pass the resolved value to Grafana.
4. Test the paused path and existing scheduling coverage.
