# Data Model: Prometheus values merge backport

No persistent data model changes are required.

The relevant transient configuration shape is:

```text
prometheus.extra_configs
└── prometheus
    └── prometheusSpec
        ├── nodeSelector       # caller-owned
        ├── tolerations        # caller-owned
        ├── other chart fields # caller-owned
        └── remoteWrite        # module-owned when VictoriaMetrics is enabled
```

The module must preserve caller-owned fields while producing the existing
module-owned remote-write endpoint.
