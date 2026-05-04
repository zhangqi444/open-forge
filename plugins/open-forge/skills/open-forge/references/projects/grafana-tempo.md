---
name: grafana-tempo
description: Grafana Tempo recipe for open-forge. Open-source high-scale distributed tracing backend requiring only object storage. Integrates with Grafana, Loki, and Prometheus.
---

# Grafana Tempo

Open-source, high-scale distributed tracing backend. Ingests traces from Jaeger, Zipkin, Kafka, and OpenTelemetry; stores them cost-efficiently in object storage (S3, GCS, Azure Blob, local disk). Deeply integrated with Grafana via TraceQL query language. Upstream: <https://github.com/grafana/tempo>. Docs: <https://grafana.com/docs/tempo/latest/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Dev / small production |
| Helm (Kubernetes) | Production K8s |
| Binary | Custom orchestration |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Object storage or local disk?" | Local for dev; S3/GCS/MinIO for production |
| preflight | "S3 bucket / MinIO endpoint and credentials?" | If using object storage |
| preflight | "Which trace ingest protocol?" | OTLP (recommended), Jaeger, Zipkin |

## Docker Compose example

```yaml
version: "3.9"
services:
  tempo:
    image: grafana/tempo:latest
    command: ["-config.file=/etc/tempo/config.yml"]
    ports:
      - "3200:3200"    # HTTP / Tempo query API
      - "4317:4317"    # OTLP gRPC
      - "4318:4318"    # OTLP HTTP
      - "9411:9411"    # Zipkin
      - "14268:14268"  # Jaeger ingest HTTP
    volumes:
      - ./tempo-config.yml:/etc/tempo/config.yml
      - tempo-data:/var/tempo

volumes:
  tempo-data:
```

### Minimal tempo-config.yml

```yaml
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
    zipkin:
    jaeger:
      protocols:
        thrift_http:
          endpoint: 0.0.0.0:14268

storage:
  trace:
    backend: local
    local:
      path: /var/tempo/blocks
    wal:
      path: /var/tempo/wal
```

For S3/MinIO storage, replace `backend: local` with S3 config: <https://grafana.com/docs/tempo/latest/configuration/#storage>

## Grafana datasource

Add a Tempo datasource in Grafana: **Type: Tempo**, **URL: http://tempo:3200**

Enable trace-to-logs correlation by linking to your Loki datasource.

## Software-layer concerns

- Port `3200`: HTTP API + Tempo UI (via Grafana)
- Ports `4317`/`4318`: OTLP gRPC/HTTP ingest
- Query language: [TraceQL](https://grafana.com/docs/tempo/latest/traceql/) — e.g. `{ .http.method = "GET" && duration > 1s }`
- Tempo requires Grafana to query — no standalone query UI
- Local disk backend is fine for dev; object storage required for production durability and scale

## Upgrade procedure

1. Pull new image: `docker compose pull tempo`
2. Restart: `docker compose up -d tempo`
3. WAL and blocks are forward-compatible within major versions

## Gotchas

- Tempo has **no standalone UI** — must use Grafana ≥ 9.x to explore traces
- Local disk fills up fast with high-traffic services — set retention in config or switch to object storage
- OTLP ingest on `4317`/`4318` conflicts with OpenTelemetry Collector if both run on the same host — pin to specific ports
- Apache Parquet is the default storage format as of Tempo 2.0 — older installations need migration before upgrading

## Links

- GitHub: <https://github.com/grafana/tempo>
- Docs: <https://grafana.com/docs/tempo/latest/>
- Getting started: <https://grafana.com/docs/tempo/latest/getting-started/>
- Docker Compose examples: <https://github.com/grafana/tempo/tree/main/example/docker-compose>
- Docker Hub: <https://hub.docker.com/r/grafana/tempo>
