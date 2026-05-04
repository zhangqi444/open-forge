---
name: grafana-alloy
description: Grafana Alloy recipe for open-forge. Open-source OpenTelemetry Collector distribution with built-in Prometheus pipelines. Collects metrics, logs, traces, and profiles for any observability backend.
---

# Grafana Alloy

Open-source OpenTelemetry Collector distribution with built-in Prometheus pipelines. Collects and forwards metrics, logs, traces, and profiles to any backend (Grafana Cloud, Loki, Mimir, Tempo, Pyroscope, or any OTel-compatible destination). Successor to Grafana Agent. Upstream: <https://github.com/grafana/alloy>. Docs: <https://grafana.com/docs/alloy/latest/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker / Docker Compose | Containerized environments |
| Helm (Kubernetes) | K8s; DaemonSet for node-level collection |
| Linux package (`apt`/`rpm`) | Bare-metal / VMs |
| Binary | Custom installs |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "What are you collecting? (metrics / logs / traces / profiles)" | Determines which components to configure |
| preflight | "Destination backend?" | Loki, Mimir, Tempo, Pyroscope, or OTel endpoint |
| preflight | "Auth token / API key for destination?" | If sending to Grafana Cloud or protected endpoint |

## Docker Compose example

```yaml
version: "3.9"
services:
  alloy:
    image: grafana/alloy:latest
    command:
      - run
      - /etc/alloy/config.alloy
      - --storage.path=/var/lib/alloy/data
    ports:
      - "12345:12345"   # Alloy UI / API
      - "4317:4317"     # OTLP gRPC (optional)
      - "4318:4318"     # OTLP HTTP (optional)
    volumes:
      - ./alloy-config.alloy:/etc/alloy/config.alloy
      - alloy-data:/var/lib/alloy/data

volumes:
  alloy-data:
```

## Example config (alloy-config.alloy)

Collect host metrics → send to Prometheus remote_write:

```alloy
prometheus.exporter.unix "localhost" {}

prometheus.scrape "local" {
  targets    = prometheus.exporter.unix.localhost.targets
  forward_to = [prometheus.remote_write.mimir.receiver]
}

prometheus.remote_write "mimir" {
  endpoint {
    url = "http://mimir:9009/api/v1/push"
    headers = { "X-Scope-OrgID" = "anonymous" }
  }
}
```

Collect logs via tail → send to Loki:

```alloy
local.file_match "varlog" {
  path_targets = [{ __path__ = "/var/log/**/*.log" }]
}

loki.source.file "varlog" {
  targets    = local.file_match.varlog.targets
  forward_to = [loki.write.default.receiver]
}

loki.write "default" {
  endpoint {
    url = "http://loki:3100/loki/api/v1/push"
  }
}
```

## Software-layer concerns

- Port `12345`: Alloy built-in UI (pipeline visualization + debugging) — accessible at http://localhost:12345
- Config language: [Alloy configuration syntax](https://grafana.com/docs/alloy/latest/concepts/configuration-syntax/) (River-based, not YAML)
- Successor to Grafana Agent (Grafana Agent is in maintenance mode); migration guide: <https://grafana.com/docs/alloy/latest/tasks/migrate/>
- Supports all OpenTelemetry Collector components plus Grafana-specific ones (Loki, Pyroscope scrape, etc.)
- DaemonSet mode in K8s: collect per-node logs/metrics without side-car per pod

## Upgrade procedure

1. Pull new image: `docker compose pull alloy`
2. Restart: `docker compose up -d alloy`
3. Check [changelog](https://github.com/grafana/alloy/releases) for config syntax changes between major versions

## Gotchas

- Config is **not YAML** — it uses the Alloy expression syntax (`.alloy` extension); don't try to write YAML
- Grafana Agent (classic) configs don't auto-convert; use the migration tool: `alloy convert --source-format=agent`
- Built-in UI on port `12345` is very useful for debugging pipelines — enable in dev; restrict in production
- `--storage.path` must be persisted for WAL (write-ahead log) to survive restarts

## Links

- GitHub: <https://github.com/grafana/alloy>
- Docs: <https://grafana.com/docs/alloy/latest/>
- Migration from Grafana Agent: <https://grafana.com/docs/alloy/latest/tasks/migrate/>
- Docker Hub: <https://hub.docker.com/r/grafana/alloy>
