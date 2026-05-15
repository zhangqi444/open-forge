---
name: uptrace
description: Uptrace recipe for open-forge. Open-source APM — OpenTelemetry traces, metrics, and logs via ClickHouse + PostgreSQL. Covers Docker Compose install, uptrace.yml config, and upgrade procedure. Derived from https://github.com/uptrace/uptrace and https://uptrace.dev/.
---

# Uptrace

Open-source Application Performance Monitoring (APM) platform built on OpenTelemetry and ClickHouse. Collects distributed traces, metrics, and logs in one UI.

- Upstream repo: https://github.com/uptrace/uptrace
- Docs: https://uptrace.dev/
- Docker Hub: https://hub.docker.com/r/uptrace/uptrace
- License: BSL 1.1 (source-available; free for self-hosting)

## What it does

Uptrace ingests OpenTelemetry telemetry (traces, metrics, logs) and stores it in ClickHouse (time-series) + PostgreSQL (metadata). It ships a query UI for traces, 50+ auto-generated dashboards for common metrics sources, alerting with email/Slack/webhook/AlertManager notifications, Grafana compatibility as a Tempo/Prometheus data source, and SSO via OpenID Connect. OpenTelemetry Collector, Prometheus, Vector, FluentBit, and CloudWatch are all supported ingestion paths.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker Compose | https://github.com/uptrace/uptrace/tree/master/example/docker | yes | Recommended. Ships ClickHouse, PostgreSQL, Redis, OTEL Collector, Grafana, Mailpit, Vector. |
| Binary | https://uptrace.dev/get/hosted/self-host | yes | Bare-metal; bring your own ClickHouse + PostgreSQL. |
| Kubernetes (Helm) | https://artifacthub.io/packages/helm/uptrace/uptrace | yes | Upstream-published Helm chart. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | Web UI port? | Integer, default 14318 | Maps to host port for the HTTP UI (container port 80). |
| preflight | OTLP gRPC port? | Integer, default 14317 | For SDK / OTEL Collector ingest. |
| preflight | Where to store data? | Path, default ./uptrace-data | Used for volume mounts. |
| config | uptrace.yml site.url? | URL, e.g. http://yourhost:14318 | Must be accessible from all clients; used for dashboard links and CORS. |
| config | uptrace.yml service.secret? | String | Cryptographic secret — generate with openssl rand -hex 32. |
| db | ClickHouse password? | String | Set in CLICKHOUSE_PASSWORD and in uptrace.yml ch.dsn. |
| db | PostgreSQL password? | String | Set in POSTGRES_PASSWORD and in uptrace.yml pg.dsn. |
| smtp (optional) | SMTP details? | Free-text | For alert email notifications via uptrace.yml alerting.email. |

## Install — Docker Compose

Source: https://github.com/uptrace/uptrace/tree/master/example/docker

```bash
# 1. Clone or download the example directory
git clone --depth 1 https://github.com/uptrace/uptrace.git
cd uptrace/example/docker

# 2. Edit uptrace.yml — set site.url, service.secret, and DB credentials
#    Edit docker-compose.yml to update CLICKHOUSE_PASSWORD, POSTGRES_PASSWORD
#    to match the credentials set in uptrace.yml

# 3. Start all services
docker compose up -d
```

Access http://localhost:14318. The default project token and DSN are shown in uptrace.yml under `projects`.

docker-compose.yml services (abbreviated):

```yaml
services:
  clickhouse:
    image: clickhouse/clickhouse-server:26.3
    environment:
      CLICKHOUSE_USER: uptrace
      CLICKHOUSE_PASSWORD: uptrace   # change this
      CLICKHOUSE_DB: uptrace
    volumes:
      - ch_data:/var/lib/clickhouse

  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: uptrace
      POSTGRES_PASSWORD: uptrace    # change this
      POSTGRES_DB: uptrace
    volumes:
      - pg_data:/var/lib/postgresql/data/pgdata

  redis:
    image: redis:6.2.2-alpine

  uptrace:
    image: uptrace/uptrace:2.0.3
    ports:
      - '14317:4317'   # OTLP gRPC
      - '14318:80'     # Web UI + OTLP HTTP
    volumes:
      - ./uptrace.yml:/etc/uptrace/config.yml
    depends_on:
      clickhouse:
        condition: service_healthy
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  otelcol:
    image: otel/opentelemetry-collector-contrib:0.123.0
    volumes:
      - ./otel-collector.yaml:/etc/otelcol-contrib/config.yaml
    ports:
      - '4317:4317'   # OTLP gRPC (for your apps)
      - '4318:4318'   # OTLP HTTP
    depends_on:
      - uptrace

  mailpit:
    image: axllent/mailpit       # local SMTP catcher for testing alerts
    ports:
      - 8025:8025

  grafana:
    image: grafana/grafana:12.0.0
```

## Software-layer concerns

### Ports

| Port (host) | Port (container) | Use |
|---|---|---|
| 14317 | 4317 | OTLP gRPC ingest |
| 14318 | 80 | Web UI, OTLP HTTP ingest, REST API |
| 4317 | 4317 | OTLP Collector gRPC (for apps sending to the collector) |
| 4318 | 4318 | OTLP Collector HTTP |
| 8025 | 8025 | Mailpit web UI (SMTP test catcher) |

### Key uptrace.yml fields

```yaml
service:
  env: hosted
  secret: CHANGE_ME       # openssl rand -hex 32

site:
  url: http://localhost:14318    # public URL of this Uptrace instance
  ingest_url: http://localhost:14318?grpc=14317

listen:
  http:
    addr: :80
  grpc:
    addr: :4317

ch:
  dsn: clickhouse://uptrace:CHANGE_PW@clickhouse:9000/uptrace?sslmode=disable

pg:
  dsn: postgresql://uptrace:CHANGE_PW@postgres:5432/uptrace?sslmode=disable

projects:
  - id: 1
    name: My Project
    token: my-project-token    # include in OTLP headers: uptrace-dsn: http://<token>@localhost:14318?grpc=14317
```

Full config reference: https://uptrace.dev/get/hosted/config

### Data directories (Docker Compose volumes)

| Volume | Contents |
|---|---|
| ch_data | ClickHouse data (traces, metrics, logs) |
| pg_data | PostgreSQL data (projects, alerts, dashboards, users) |

## Upgrade procedure

1. Check release notes: https://github.com/uptrace/uptrace/releases
2. Back up data:
   ```bash
   docker compose stop uptrace
   docker compose exec postgres pg_dump -Uuptrace uptrace > uptrace-pg-$(date +%F).sql
   # ClickHouse: copy ch_data volume or use clickhouse-backup
   ```
3. Update the uptrace image tag in docker-compose.yml:
   ```bash
   docker compose pull uptrace
   docker compose up -d uptrace
   ```
4. Uptrace runs database migrations on startup. Check logs:
   ```bash
   docker compose logs -f uptrace
   ```
5. Update the OpenTelemetry Collector image separately if needed.

## Connecting your application

Point your OpenTelemetry SDK or Collector to Uptrace using the DSN format:

```
# OTLP exporter URL (include uptrace-dsn header)
OTLP endpoint: http://localhost:14318
Header: uptrace-dsn: http://<token>@localhost:14318?grpc=14317

# Or via the included OTEL Collector (recommended for production)
OTLP endpoint: http://localhost:4317 (gRPC) or http://localhost:4318 (HTTP)
```

The OTEL Collector config in `otel-collector.yaml` forwards to Uptrace automatically.

## Gotchas

- **uptrace.yml is required.** The Docker image has no built-in default config — you must mount `./uptrace.yml:/etc/uptrace/config.yml`. Copying it from the example directory is the easiest start.
- **service.secret must be set.** The default `FIXME` value will cause Uptrace to refuse to start. Generate a secret with `openssl rand -hex 32`.
- **ClickHouse version compatibility.** Uptrace pins ClickHouse to a specific version (26.3 in the example compose). ClickHouse 26.3+ has a known bug with certain queries on the spans view when not filtered by trace_id — the compose file comment documents this. Don't upgrade ClickHouse without checking release notes.
- **Two OTLP ingestion paths.** Port 14317/14318 go directly to Uptrace; port 4317/4318 go to the OTEL Collector which forwards to Uptrace. For production, prefer the Collector path — it adds buffering, retry, and lets you fan out to multiple backends.
- **site.url must match how clients reach Uptrace.** CORS validation uses this URL. If it's wrong, browser-based SDKs will fail with CORS errors.
- **BSL license.** Uptrace uses Business Source License 1.1 — free for self-hosting, but check the LICENSE file for use restrictions if building a commercial product on top of it.
- **Grafana integration.** Add Uptrace as a Grafana data source: Tempo (for traces) at http://uptrace:80/api/tempo and Prometheus (for metrics) at http://uptrace:80. The example Compose wires this up automatically.

## Links

- Repo: https://github.com/uptrace/uptrace
- Docs: https://uptrace.dev/
- Docker example: https://github.com/uptrace/uptrace/tree/master/example/docker
- Config reference: https://uptrace.dev/get/hosted/config
- Releases: https://github.com/uptrace/uptrace/releases
- Helm chart: https://artifacthub.io/packages/helm/uptrace/uptrace
