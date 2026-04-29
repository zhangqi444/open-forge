---
name: signoz-project
description: SigNoz recipe for open-forge. MIT + Enterprise-dual-licensed observability platform — all three pillars (logs, metrics, traces) in one UI, plus APM + LLM observability. Open-source alternative to Datadog / New Relic / Dynatrace. OpenTelemetry-native (OTLP gRPC + HTTP receivers on :4317/:4318 out of the box). Built on ClickHouse (column-store, fast), Zookeeper (coordination), plus the SigNoz app + otel-collector. Covers the official docker-compose stack (5 containers: init-clickhouse + zookeeper-1 + clickhouse + signoz + otel-collector + migrator), exposes OTLP :4317/:4318 for instrumented apps, and the Helm/Kubernetes/AWS-ECS deploy paths. Includes the SIGNOZ_TOKENIZER_JWT_SECRET=secret default warning (change it!), ClickHouse 25.5 resource needs, and the paid SigNoz Cloud tier positioning.
---

# SigNoz

Open-source all-in-one observability platform. Upstream: <https://github.com/SigNoz/signoz>. Docs: <https://signoz.io/docs>. Website: <https://signoz.io>. Hosted: <https://signoz.io/teams> (SigNoz Cloud).

**Positioning:** open-source alternative to Datadog / New Relic / Dynatrace / AppDynamics — all three observability pillars (logs + metrics + traces) unified in one UI, plus APM and LLM observability. OpenTelemetry-native from the ground up.

License: MIT for the OSS edition, Enterprise edition adds SSO, RBAC, advanced retention, multi-tenancy on top.

## Features

- **Distributed Tracing** — OpenTelemetry-native. Flamegraphs, Gantt charts, span details. Track user requests across microservices.
- **Application Performance Monitoring** — out-of-box p99 latency, error rate, Apdex, operations/sec, DB/external call monitoring.
- **Logs Management** — ClickHouse-backed log storage, fast search, log-to-trace correlation, log-based dashboards.
- **Metrics + Dashboards** — customizable dashboards, rich query builder, PromQL support, multiple panel types.
- **LLM Observability** — track LLM calls, token usage, costs, prompt/response analysis (OpenAI / Anthropic / others via OTel).
- **Alerts** — threshold + anomaly rules on metrics/logs/traces; Slack/PagerDuty/webhook notifications.
- **Service maps** — auto-discovered from trace data.
- **Exception tracking** — group exceptions, stack traces, affected users.

## Architecture — the 5-container stack

From upstream `deploy/docker/docker-compose.yaml`:

| Service | Image | Role |
|---|---|---|
| `init-clickhouse` | `clickhouse/clickhouse-server:25.5.6` | One-shot: fetches + installs `histogram-quantile` UDF binary into ClickHouse user_scripts. |
| `zookeeper-1` | `signoz/zookeeper:3.7.1` | ClickHouse coordination (single node OK; cluster in HA mode). |
| `clickhouse` | `clickhouse/clickhouse-server:25.5.6` | Column-store DB — all telemetry data (traces, logs, metrics). |
| `signoz` | `signoz/signoz:v0.120.0` | Main app — UI, query engine, alertmanager (built-in), auth. SQLite meta-store. |
| `otel-collector` | `signoz/signoz-otel-collector:v0.144.3` | OTLP receiver on `:4317` (gRPC) + `:4318` (HTTP); writes to ClickHouse. |
| `signoz-telemetrystore-migrator` | `signoz/signoz-otel-collector:v0.144.3` | One-shot ClickHouse schema migrations. |

ClickHouse is where the heavy data lives. SigNoz's SQLite is just the app's own metadata (users, dashboards, alerts).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (single-node) | <https://github.com/SigNoz/signoz/tree/main/deploy/docker> | ✅ Recommended | Home lab / small prod. |
| Docker Compose HA (`docker-compose.ha.yaml`) | <https://github.com/SigNoz/signoz/blob/main/deploy/docker/docker-compose.ha.yaml> | ✅ | Multi-replica single-host HA. |
| Docker Swarm | <https://github.com/SigNoz/signoz/tree/main/deploy/docker-swarm> | ✅ | Swarm users. |
| Kubernetes (Helm) | <https://github.com/SigNoz/charts> | ✅ | Clusters (recommended for prod scale). |
| AWS ECS | <https://signoz.io/docs/install/docker/aws-ec2/> | ✅ | AWS users. |
| SigNoz Cloud | <https://signoz.io/teams> | Paid | Don't self-host. |

Install script: `curl -sL https://signoz.io/install.sh | bash` — runs the Docker Compose install for you.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `docker-compose-ha` / `docker-swarm` / `kubernetes-helm` / `aws-ecs` | Drives section. |
| ports | "SigNoz UI port?" | Default `8080` | Map externally. |
| ports | "OTLP ports?" | Default `4317` (gRPC) + `4318` (HTTP) | Expose to apps you want to instrument. |
| resources | "Host resources?" | Min 4 GB RAM + 2 CPU + 10 GB disk | ClickHouse is the hungry one. |
| retention | "Retention (days)?" | Default traces 30d / metrics 90d / logs 30d | Configurable at runtime via UI. |
| secrets | "JWT secret?" | Random 64-char hex | `SIGNOZ_TOKENIZER_JWT_SECRET` — default `secret` is INSECURE. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `caddy` / `traefik` / `nginx` / `none` | SigNoz speaks HTTP; terminate TLS externally. |
| tls | "OTLP TLS?" | Boolean | Usually sent from trusted network. For public OTLP, put behind a TLS-terminating proxy. |

## Install — Docker Compose (standard)

Official quick install:

```bash
git clone -b main https://github.com/SigNoz/signoz.git
cd signoz/deploy/docker
docker compose up -d
# → http://<host>:8080/
```

Or the one-liner script:

```bash
curl -sL https://signoz.io/install.sh | bash
```

The compose file uses anchored YAML defaults and deploys 6 containers (5 services + init + migrator). First-run setup creates an admin account via the UI.

Once up, instrument an app with OpenTelemetry and send OTLP to `<signoz-host>:4317` (gRPC) or `<signoz-host>:4318` (HTTP):

```bash
# Example: Node app with OTel SDK
export OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz.example.com:4318
export OTEL_RESOURCE_ATTRIBUTES=service.name=my-app,deployment.environment=prod
node --require '@opentelemetry/auto-instrumentations-node/register' app.js
```

## Key configuration

### `SIGNOZ_TOKENIZER_JWT_SECRET` ⚠️

Default in upstream compose is literally `secret`. This MUST be changed for any non-eval deployment:

```yaml
signoz:
  environment:
    - SIGNOZ_TOKENIZER_JWT_SECRET=<64-char-random>
```

Generate: `openssl rand -hex 64`.

### ClickHouse sizing

ClickHouse is the storage workhorse. For anything beyond eval:

- **RAM**: 4 GB min; 8-16 GB for moderate traffic.
- **Disk**: SSD strongly preferred. Plan 100 GB+ for 30-day retention at modest ingest (~1 GB/day ingest → ~3-5 GB/day stored compressed).
- **CPU**: 2-4 cores min.

### Retention

Configured in SigNoz UI: **Settings → General → Retention period**. Adjusts ClickHouse TTL on tables. Defaults typically:

- Traces: 30 days
- Logs: 30 days
- Metrics: 90 days

Retention drives disk usage linearly — halving retention halves disk.

### Collector config

`deploy/docker/otel-collector-config.yaml` is the otel-collector pipeline config. Default accepts OTLP on `:4317` + `:4318`, runs through a batcher, writes to ClickHouse. Customize receivers/processors there if you need to accept other formats (Jaeger, Zipkin, Prometheus scrape, syslog, etc.).

## Reverse proxy (Caddy example)

```caddy
signoz.example.com {
    reverse_proxy signoz:8080
}

# OTLP HTTP ingest on a public hostname
otlp.example.com {
    reverse_proxy otel-collector:4318
}

# For gRPC OTLP, use a TCP proxy (Caddy has limited gRPC proxying; use nginx / Envoy / Traefik)
```

## Instrumentation cheat sheet

SigNoz uses OpenTelemetry SDKs — nothing SigNoz-specific. Point any OTel SDK at the SigNoz otel-collector:

| Language | Setup |
|---|---|
| Python | `opentelemetry-distro` + `opentelemetry-bootstrap -a install` + `opentelemetry-instrument` |
| Node.js | `@opentelemetry/auto-instrumentations-node` |
| Java | `-javaagent:opentelemetry-javaagent.jar` |
| Go | `go.opentelemetry.io/otel` + manual instrumentation |
| .NET | OpenTelemetry .NET SDK + auto-instrumentation |
| Rust / Ruby / PHP | OTel SDKs available |

Docs: <https://signoz.io/docs/instrumentation/>.

## Data layout

| Volume | Content |
|---|---|
| `signoz-clickhouse` | ClickHouse data — traces, logs, metrics tables. BIG. |
| `signoz-sqlite` | SigNoz app metadata — users, dashboards, alerts, saved views. TINY. |
| `signoz-zookeeper-1` | Zookeeper coordination data. TINY. |

**Backup priority:**

1. **ClickHouse** — the bulk of the data. Use `clickhouse-backup` tool or `BACKUP TABLE ... TO S3` (ClickHouse-native). For small deploys, `docker cp` while paused works but is slow.
2. **SigNoz SQLite** (`/var/lib/signoz/signoz.db`) — dashboards, alerts, users. Small + critical.
3. Zookeeper — rebuildable; don't bother.

For prod, attach ClickHouse to S3-backed storage (ClickHouse supports tiered storage — hot on local SSD, cold on S3).

## Upgrade procedure

```bash
# Pin VERSION + OTELCOL_TAG in a .env file first
cd signoz/deploy/docker
git pull
docker compose pull
docker compose up -d
docker compose logs -f signoz-telemetrystore-migrator
```

The `signoz-telemetrystore-migrator` runs ClickHouse schema migrations (`migrate bootstrap`, `migrate sync up`, `migrate async up`). Wait for it to complete before using the UI.

Release notes: <https://github.com/SigNoz/signoz/releases>.

## Kubernetes (Helm)

```bash
helm repo add signoz https://charts.signoz.io
helm repo update
helm install signoz signoz/signoz -n platform --create-namespace \
  --values values.yaml
```

Helm chart (<https://github.com/SigNoz/charts>) deploys ClickHouse via ClickHouse-Operator, OTel Collector as a DaemonSet (for node-level log collection) + Deployment (for OTLP ingest), SigNoz as a Deployment.

## Gotchas

- **Default `SIGNOZ_TOKENIZER_JWT_SECRET=secret`** — upstream compose ships with the literal string `secret`. Anyone who knows this can forge JWTs. CHANGE IT before exposing beyond localhost.
- **Docker Compose build contexts** — compose references `../common/clickhouse/*.xml` etc. If you copy `docker-compose.yaml` standalone, you're missing these files. Either clone the whole repo OR copy the `../common/` tree alongside.
- **ClickHouse is memory-hungry.** On a 2 GB VM, you'll OOM. 4 GB minimum, 8 GB for real workloads.
- **Retention drives cost.** 30 days at 1 GB/day ingest → 30 GB storage (compressed). Bump to 90 days = 90 GB. For high-volume apps, tune aggressively.
- **Zookeeper is single-node** in the default compose. For HA, use `docker-compose.ha.yaml` which adds zookeeper-2 + zookeeper-3.
- **`histogram-quantile` UDF is fetched at runtime** by `init-clickhouse` from GitHub releases. If your host can't reach github.com, init fails silently + queries using histogram percentiles break. Pre-download in air-gapped environments.
- **OpenTelemetry versions matter.** OTLP protocol is stable but processor/attribute conventions evolve. Keep SDK versions reasonably current.
- **Log ingestion path is distinct from host-log-scraping.** SigNoz accepts OTLP logs; it doesn't tail files. For host/container logs, run a separate otel-collector as a DaemonSet (K8s) or `filelogreceiver` config on each host.
- **SigNoz is NOT Grafana.** Dashboards + alerting are SigNoz-specific (their own query builder, own dashboard format). Can't import Grafana dashboards directly.
- **Metrics ingestion is OTel-centric.** For Prometheus-scrape workflows, you need to either (a) have apps push to the otel-collector via `prometheusremotewrite` or (b) configure the otel-collector's `prometheus` receiver to scrape.
- **Alertmanager is built IN to SigNoz.** Don't run an external Prometheus Alertmanager expecting SigNoz to federate. Configure alert destinations in SigNoz UI.
- **SSO / RBAC / multi-tenancy = paid Enterprise tier.** OSS is single-org. For team access control, reverse-proxy + external auth (Authelia/Authentik) is the common workaround, or pay for Enterprise.
- **Kubernetes + Helm + ClickHouse-Operator** is opinionated — works well but is a committed operational choice. Alternatives like running ClickHouse outside the cluster (managed ClickHouse Cloud) are supported via config.
- **OTel collector health** — the `otel-collector` container is the ingest bottleneck. Watch its memory/CPU. Scale with `otel-collector` replicas if single-instance is saturated.
- **Trace sampling** — default is 100% ingest. For high-volume services, implement head-based sampling in the SDK OR tail sampling in the otel-collector (not SigNoz UI — collector config).
- **Data exported from SigNoz** is tricky — ClickHouse SQL works if you connect directly, but there's no "export dashboard" button for wholesale data portability. Vendor lock-in-ish.
- **LLM observability** piggybacks on OpenTelemetry GenAI semantic conventions. Apps instrumented with OpenLLMetry / LangTrace / OpenInference libraries → SigNoz picks up LLM traces automatically.
- **Self-hosting vs SigNoz Cloud cost trade-off** — at scale, managed services often come out cheaper once you account for ClickHouse ops burden. Evaluate honestly.
- **ClickHouse replication (`docker-compose.ha.yaml`)** uses 3 ClickHouse nodes + 3 ZK nodes — requires ~16 GB RAM total minimum. Overkill for small deploys.

## Links

- Upstream repo: <https://github.com/SigNoz/signoz>
- Docs: <https://signoz.io/docs>
- Installation: <https://signoz.io/docs/install/>
- Docker install: <https://signoz.io/docs/install/docker/>
- Kubernetes install: <https://signoz.io/docs/install/kubernetes/>
- Instrumentation: <https://signoz.io/docs/instrumentation/>
- Docker compose files: <https://github.com/SigNoz/signoz/tree/main/deploy/docker>
- Helm charts: <https://github.com/SigNoz/charts>
- Install script: <https://signoz.io/install.sh>
- Releases: <https://github.com/SigNoz/signoz/releases>
- Docker Hub: <https://hub.docker.com/u/signoz>
- SigNoz Cloud: <https://signoz.io/teams>
- Slack community: <https://signoz.io/slack>
- OpenTelemetry: <https://opentelemetry.io>
- ClickHouse: <https://clickhouse.com/docs>
- vs Datadog / vs New Relic: <https://signoz.io/comparisons/>
