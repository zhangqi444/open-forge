---
name: jaeger
description: Recipe for Jaeger — open-source, end-to-end distributed tracing system. CNCF graduated project.
---

# Jaeger

Open-source distributed tracing platform created by Uber Technologies, donated to CNCF (graduated project). Collects traces from instrumented microservices, stores spans, and provides a UI to visualize request flows, latency bottlenecks, and service dependencies. Jaeger v2 is built on top of the OpenTelemetry Collector — it is now an OTEL Collector distribution with Jaeger UI/query. Upstream: <https://github.com/jaegertracing/jaeger>. Docs: <https://www.jaegertracing.io/docs/>. License: Apache-2.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker all-in-one | <https://www.jaegertracing.io/docs/latest/getting-started/> | Yes | Dev/evaluation; in-memory storage, single container |
| Docker Compose (with Elasticsearch/Cassandra) | <https://www.jaegertracing.io/docs/latest/deployment/> | Yes | Production with persistent storage |
| Kubernetes Helm chart | <https://github.com/jaegertracing/helm-charts> | Yes | Kubernetes deployments |
| Jaeger Operator | <https://www.jaegertracing.io/docs/latest/operator/> | Yes | Kubernetes operator with auto-sidecar injection |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Storage backend? | memory / elasticsearch / cassandra / badger | All; memory is ephemeral |
| infra | Elasticsearch URL? | http://host:9200 | If using ES backend |
| infra | Port for Jaeger UI? | Port (default 16686) | All |
| software | Sampling strategy? | remote / const / probabilistic / rate_limiting | Optional |

## Software-layer concerns

### Docker all-in-one (quickstart, in-memory)

```bash
docker run --rm --name jaeger \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/jaeger:latest
```

- Port 16686: Jaeger UI
- Port 4317: OTLP gRPC (send traces here)
- Port 4318: OTLP HTTP

All data is in-memory and lost on container stop. For evaluation only.

### Docker Compose with Elasticsearch (production)

```yaml
services:
  elasticsearch:
    image: elasticsearch:8.13.0
    container_name: jaeger-es
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms1g -Xmx1g
    volumes:
      - jaeger-es:/usr/share/elasticsearch/data

  jaeger:
    image: jaegertracing/jaeger:latest
    container_name: jaeger
    restart: unless-stopped
    depends_on:
      - elasticsearch
    ports:
      - "16686:16686"   # UI
      - "4317:4317"     # OTLP gRPC
      - "4318:4318"     # OTLP HTTP
    environment:
      SPAN_STORAGE_TYPE: elasticsearch
      ES_SERVER_URLS: http://elasticsearch:9200

volumes:
  jaeger-es:
```

### Legacy ports (Jaeger v1 / still supported in v2)

| Port | Protocol | Description |
|---|---|---|
| 4317 | gRPC | OTLP traces (primary in v2) |
| 4318 | HTTP | OTLP traces (primary in v2) |
| 14268 | HTTP | Jaeger Thrift (legacy) |
| 14250 | gRPC | Jaeger gRPC model (legacy) |
| 6831 | UDP | Jaeger compact Thrift (legacy) |
| 16686 | HTTP | Jaeger UI + query API |

### Jaeger v2 note

Jaeger v2 is rewritten as an OpenTelemetry Collector distribution. The config format changed from the v1 YAML to OTEL Collector pipeline config. See the v2 migration guide: <https://www.jaegertracing.io/docs/latest/migration/>

### Sampling configuration

```yaml
# Remote sampling (recommended for production)
# Configure in Jaeger's sampling strategies file
{
  "service_strategies": [
    {
      "service": "my-service",
      "type": "probabilistic",
      "param": 0.1
    }
  ],
  "default_strategy": {
    "type": "probabilistic",
    "param": 0.001
  }
}
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

For v1 to v2 upgrades, follow the migration guide carefully: <https://www.jaegertracing.io/docs/latest/migration/>. The config format changed significantly.

## Gotchas

- In-memory storage: the all-in-one container loses all traces on restart. Always use a persistent backend (Elasticsearch, Cassandra, or Badger) for any non-throwaway use.
- Jaeger v2 config format: completely different from v1 (now uses OTEL Collector pipeline YAML). Do not apply v1 configs to v2.
- Elasticsearch version: Jaeger supports specific ES versions — check the compatibility matrix in the docs before picking an ES version.
- xpack.security: the example above disables ES security for simplicity. In production, enable TLS and auth and set `ES_TLS_*` env vars in the Jaeger container.
- Trace volume: high-throughput services can generate enormous trace volumes. Use head-based or tail-based sampling to control storage growth.
- OpenTelemetry SDK preferred: for new instrumentation, use the OpenTelemetry SDK (which natively sends OTLP) rather than the older Jaeger client libraries (which are deprecated).

## Links

- GitHub: <https://github.com/jaegertracing/jaeger>
- Docs: <https://www.jaegertracing.io/docs/latest/>
- Getting started: <https://www.jaegertracing.io/docs/latest/getting-started/>
- Docker Hub: <https://hub.docker.com/r/jaegertracing/jaeger>
- Helm charts: <https://github.com/jaegertracing/helm-charts>
- v1 to v2 migration: <https://www.jaegertracing.io/docs/latest/migration/>
