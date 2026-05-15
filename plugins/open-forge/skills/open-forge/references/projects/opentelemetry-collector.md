---
name: opentelemetry-collector
description: Recipe for OpenTelemetry Collector — vendor-agnostic telemetry pipeline for receiving, processing, and exporting traces, metrics, and logs.
---

# OpenTelemetry Collector

Vendor-agnostic, open-source telemetry agent and pipeline. Receives telemetry (traces, metrics, logs) from instrumented applications via OTLP (and legacy formats like Jaeger, Prometheus, Zipkin), processes/transforms data, and exports to any backend (Jaeger, Tempo, Prometheus, Loki, Datadog, New Relic, etc.). Eliminates the need to run multiple per-vendor agents. Part of CNCF. Two distributions: **core** (stable, minimal) and **contrib** (all community receivers/exporters). Upstream: <https://github.com/open-telemetry/opentelemetry-collector>. Contrib: <https://github.com/open-telemetry/opentelemetry-collector-contrib>. Docs: <https://opentelemetry.io/docs/collector/>. License: Apache-2.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/otel/opentelemetry-collector-contrib> | Yes | Recommended for containerized environments |
| Docker Compose | <https://opentelemetry.io/docs/collector/getting-started/> | Yes | Local/dev; integrate with app stack |
| Linux binary/package | <https://opentelemetry.io/docs/collector/installation/> | Yes | Bare-metal agent; RPM/DEB packages available |
| Kubernetes (Helm + Operator) | <https://opentelemetry.io/docs/platforms/kubernetes/helm/collector/> | Yes | Production Kubernetes deployments |
| OpenTelemetry Operator | <https://github.com/open-telemetry/opentelemetry-operator> | Yes | Kubernetes operator for auto-injection |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| software | Which telemetry backends to export to? | List (Jaeger, Prometheus, Tempo, Loki, etc.) | Drives exporter config |
| software | Which protocols to receive? | OTLP gRPC/HTTP, Jaeger, Zipkin, Prometheus | Drives receiver config |
| infra | OTLP gRPC port? | Port (default 4317) | All |
| infra | OTLP HTTP port? | Port (default 4318) | All |
| software | Sampling strategy? | always_on / always_off / tracesamplerate | Optional |

## Software-layer concerns

### Docker Compose with config file

```yaml
services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.152.0
    container_name: otel-collector
    restart: unless-stopped
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - "4317:4317"    # OTLP gRPC
      - "4318:4318"    # OTLP HTTP
      - "8888:8888"    # Collector metrics (Prometheus scrape)
      - "8889:8889"    # Prometheus exporter endpoint
      - "13133:13133"  # Health check
```

### Example config (otel-collector-config.yaml)

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  prometheus:
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          scrape_interval: 10s
          static_configs:
            - targets: ['0.0.0.0:8888']

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 512

exporters:
  otlp/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true
  prometheus:
    endpoint: "0.0.0.0:8889"
  logging:
    loglevel: debug

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp/jaeger, logging]
    metrics:
      receivers: [otlp, prometheus]
      processors: [memory_limiter, batch]
      exporters: [prometheus, logging]
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [logging]
```

### Core vs Contrib

| Distribution | Image | Use when |
|---|---|---|
| core | otel/opentelemetry-collector | Only need OTLP + basic exporters (Prometheus, logging) |
| contrib | otel/opentelemetry-collector-contrib | Need Jaeger, Kafka, Loki, cloud provider exporters, etc. |

Use **contrib** for most real deployments — it includes all community receivers and exporters.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Review the changelog at <https://github.com/open-telemetry/opentelemetry-collector/releases>. Breaking changes to config format do occur between minor versions — check migration guides.

## Gotchas

- Core vs Contrib: the core image has minimal receivers/exporters. Use contrib unless you know you only need core components.
- Config validation: the collector exits immediately on config errors. Always validate: `docker run --rm otel/opentelemetry-collector-contrib validate --config=./config.yaml`
- `memory_limiter` processor: always include this in production to prevent OOM — the collector can buffer significant data in memory.
- `batch` processor: combine with `memory_limiter` for efficiency. Place `memory_limiter` first in the processor chain.
- Port 8888: the collector exposes its own Prometheus metrics here — scrape it to monitor collector health.
- Kubernetes: the OpenTelemetry Operator supports auto-instrumentation injection and collector lifecycle management — preferred for K8s environments.

## Links

- GitHub (core): <https://github.com/open-telemetry/opentelemetry-collector>
- GitHub (contrib): <https://github.com/open-telemetry/opentelemetry-collector-contrib>
- Getting started: <https://opentelemetry.io/docs/collector/getting-started/>
- Configuration reference: <https://opentelemetry.io/docs/collector/configuration/>
- Component registry: <https://opentelemetry.io/ecosystem/registry/>
- Docker Hub (contrib): <https://hub.docker.com/r/otel/opentelemetry-collector-contrib>
