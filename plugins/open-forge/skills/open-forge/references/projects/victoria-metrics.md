---
name: victoria-metrics
description: VictoriaMetrics recipe for open-forge. Fast, cost-effective, scalable time-series database and long-term Prometheus-compatible storage. Single binary, no dependencies.
---

# VictoriaMetrics

Fast, cost-effective, scalable monitoring solution for time-series data. Drop-in Prometheus-compatible storage with better compression and performance. Single binary, no external dependencies. Supports PromQL + MetricsQL, Prometheus remote_write, InfluxDB line protocol, Graphite, OpenTelemetry, and more. Apache 2.0 licensed. Upstream: <https://github.com/VictoriaMetrics/VictoriaMetrics>. Docs: <https://docs.victoriametrics.com/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (single-node) | Dev / small production; single binary |
| Docker Compose | Single-node with Grafana stack |
| Helm (vmoperator / vm-cluster) | K8s; cluster mode for horizontal scale |
| Binary | Bare-metal; lightest footprint |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Single-node or cluster mode?" | Single-node handles up to ~10M active series; cluster for larger |
| preflight | "Retention period?" | Default 1 month; e.g. `6` = 6 months, `12` = 1 year |
| preflight | "Storage path?" | Persistent volume path; default `/victoria-metrics-data` |

## Docker Compose example (single-node + Grafana)

```yaml
version: "3.9"
services:
  victoriametrics:
    image: victoriametrics/victoria-metrics:latest
    restart: unless-stopped
    ports:
      - "8428:8428"    # HTTP: query API, push endpoint, UI
    volumes:
      - vm-data:/victoria-metrics-data
    command:
      - --storageDataPath=/victoria-metrics-data
      - --retentionPeriod=6    # months

  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  vm-data:
  grafana-data:
```

## Prometheus remote_write to VictoriaMetrics

```yaml
# prometheus.yml
remote_write:
  - url: http://victoriametrics:8428/api/v1/write
```

## Grafana datasource

Type: **Prometheus**, URL: `http://victoriametrics:8428`

VictoriaMetrics implements the Prometheus query API — no special plugin needed.

## Software-layer concerns

- Port `8428`: all-in-one HTTP endpoint (push, query, UI at `/vmui`)
- Built-in UI at `http://victoriametrics:8428/vmui` — explore metrics, run MetricsQL queries
- MetricsQL extends PromQL with extra functions; all PromQL queries work unchanged
- Compression: 5–10× better than Prometheus for most workloads
- No WAL recovery needed — designed for crash safety without complex recovery
- Enterprise features (downsampling, multi-retention, anomaly detection) available as separate binaries/license

## Upgrade procedure

1. Pull new image: `docker compose pull victoriametrics`
2. Restart: `docker compose up -d victoriametrics`
3. Data format is forward-compatible within minor versions; check changelog for major version jumps

## Gotchas

- Default retention is **1 month** — set `--retentionPeriod` explicitly for longer storage
- Single-node does not support horizontal sharding — switch to cluster mode for >10M active series
- `victoriametrics/victoria-metrics` is the single-node image; cluster uses separate `vminsert`, `vmselect`, `vmstorage` images
- VictoriaMetrics scrapes Prometheus exporters natively — you don't need a separate Prometheus instance

## Links

- GitHub: <https://github.com/VictoriaMetrics/VictoriaMetrics>
- Docs: <https://docs.victoriametrics.com/>
- Quick start: <https://docs.victoriametrics.com/victoriametrics/quick-start/>
- Docker Hub: <https://hub.docker.com/r/victoriametrics/victoria-metrics>
