# Scrape input validation

Reject malformed VictoriaMetrics inline scrape jobs at both module entry points while preserving heterogeneous lists and their order. Null and empty inputs remain supported. Each supplied job must have a job_name.
