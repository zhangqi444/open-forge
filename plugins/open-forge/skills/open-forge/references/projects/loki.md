---
name: loki-project
description: Grafana Loki recipe for open-forge. AGPL-3.0 horizontally-scalable multi-tenant log aggregation system inspired by Prometheus — unlike ELK or Splunk, Loki does NOT index log content, only labels. This makes it 10-100x cheaper to operate than full-text-indexed alternatives while still being queryable via LogQL. Multiple deploy modes — single-binary (monolithic), simple-scalable (read/write/backend split), microservices (production-scale). Pair with Alloy (formerly Promtail, feature-complete) or Docker Driver Client for log shipping + Grafana for querying. Covers the docker-compose single-binary stack, Helm chart reality (forking to `grafana-community/helm-charts` March 2026 for OSS users), object-storage layout (S3/GCS/Azure/MinIO), and the key tradeoff vs ELK.
---

# Loki

AGPL-3.0 log aggregation system by Grafana Labs. Upstream: <https://github.com/grafana/loki>. Docs: <https://grafana.com/docs/loki/latest/>.

> **"Like Prometheus, but for logs."**

## Core design — what makes Loki different

Loki's defining tradeoff vs ELK (Elasticsearch + Logstash + Kibana) / Splunk / Graylog:

- **No full-text indexing on log content.** Loki indexes metadata (labels like `job=nginx, level=error, env=prod`) plus chunked/compressed raw log text. Full-text search happens at query time, not index time.
- **Result:** massively cheaper to operate (~10-100x cheaper storage/compute than ELK at the same log volume).
- **Tradeoff:** queries without a label filter can be slow (must scan raw logs). Good label hygiene is essential.
- **Uses same label model as Prometheus.** `job=`, `instance=`, `env=`, `container=`, etc. — you can pivot between metrics and logs using the same selectors.
- **Push-based ingest** (vs Prometheus pull) — agents push logs to Loki, not the other way around.
- **Object storage backend** — chunks + index stored in S3 / GCS / Azure Blob / MinIO / filesystem. Compute (ingesters/queriers) is stateless.

## Architecture (at a glance)

A Loki-based logging stack has 3 components:

| Component | Role |
|---|---|
| **Alloy** (ex-Promtail) | Agent — scrapes log files / pods / Docker containers / journald, ships to Loki. |
| **Loki** | Main service — ingests, stores, queries logs. |
| **Grafana** | Query UI — LogQL queries, dashboards, log panels alongside metrics. |

Note from upstream: **Alloy replaced Promtail.** Promtail is "feature complete" — future work is in <https://github.com/grafana/alloy>. Existing Promtail deploys continue to work.

## Loki deployment modes

Per upstream docs:

| Mode | Processes | Use case |
|---|---|---|
| **Monolithic / single-binary** | All components in one process | Home labs, small prod (<100 GB/day), getting started. |
| **Simple Scalable** | Split into `read`, `write`, `backend` targets | Mid-scale prod (~100 GB/day – few TB/day). |
| **Microservices** | Each component as its own process: `distributor`, `ingester`, `querier`, `query-frontend`, `query-scheduler`, `ruler`, `compactor`, `index-gateway`, `store-gateway`, `bloom-*` | Large-scale prod (TB/day+). |

Set `-target=all` / `-target=read,write,backend` / specific targets via config.

## ⚠️ Helm chart repo moving March 2026

Per upstream README:

> Effective March 16, 2026, the Grafana Loki Helm chart will be forked to a new repository [`grafana-community/helm-charts`](https://github.com/grafana-community/helm-charts). The chart in the Loki repository will continue to be maintained for **GEL** (Grafana Enterprise Logs) **users only**. See [grafana/loki#20705](https://github.com/grafana/loki/issues/20705) for details.

OSS self-hosters: use `grafana-community/helm-charts` for new installs after the fork date. Existing installs of the old chart continue to work but won't receive OSS-focused updates.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker image (`grafana/loki`) | Docker Hub | ✅ Recommended for single-node | Home labs, small prod. |
| Docker Compose stack | <https://github.com/grafana/loki/blob/main/production/docker-compose.yaml> | ✅ | Single-binary Loki + Alloy/Promtail + Grafana together. |
| Helm chart (OSS) | <https://github.com/grafana-community/helm-charts> (from Mar 2026) | ✅ | Kubernetes. |
| Helm chart (GEL) | <https://github.com/grafana/loki/tree/main/production/helm/loki> | Paid | Enterprise. |
| Binary / systemd | <https://grafana.com/docs/loki/latest/setup/install/local/> | ✅ | Bare-metal. |
| Tanka (Grafana-Tanka jsonnet) | <https://grafana.com/docs/loki/latest/setup/install/tanka/> | ✅ | Microservices K8s deploy, production-grade. |
| Docker Driver Client (logging driver, as source) | <https://grafana.com/docs/loki/latest/send-data/docker-driver/> | ✅ | Ship Docker container logs directly to Loki without an agent. |
| Grafana Cloud Logs | <https://grafana.com/products/cloud/logs/> | Paid | Hosted. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Deployment mode?" | `AskUserQuestion`: `monolithic (single-binary)` / `simple-scalable` / `microservices` | Monolithic = default for small installs. |
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `docker-run` / `helm-k8s` / `binary-systemd` | Drives section. |
| storage | "Object storage backend?" | `AskUserQuestion`: `filesystem (local)` / `s3` / `gcs` / `azure-blob` / `minio` | Filesystem is fine for <100 GB/day; use object storage for scale. |
| ports | "Loki HTTP port?" | Default `3100` | |
| tenancy | "Multi-tenancy?" | Boolean | Single-tenant = `auth_enabled: false`. Multi-tenant adds `X-Scope-OrgID` header requirements. |
| retention | "Log retention?" | e.g. `30d`, `90d`, `0 (forever)` | Configured in `limits_config.retention_period`. |
| agent | "Log shipper?" | `AskUserQuestion`: `alloy (recommended)` / `promtail (existing installs)` / `docker-driver` / `fluentbit` / `vector` / `other` | Alloy for new installs. |

## Install — Docker Compose (single-binary + Alloy + Grafana)

Based on upstream `production/docker-compose.yaml` (<https://github.com/grafana/loki/blob/main/production/docker-compose.yaml>) — simplified for home-lab use:

```yaml
# compose.yaml
networks:
  loki:

services:
  loki:
    image: grafana/loki:latest            # pin a version in prod, e.g. :3.2.1
    container_name: loki
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    networks: [loki]
    # For persistent storage, mount a data dir:
    # volumes:
    #   - loki-data:/loki
    #   - ./loki-config.yaml:/etc/loki/local-config.yaml:ro

  promtail:
    # Promtail is feature-complete — new installs should use Alloy instead:
    # image: grafana/alloy:latest
    # command: run --server.http.listen-addr=0.0.0.0:12345 /etc/alloy/config.alloy
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - /var/log:/var/log
    command: -config.file=/etc/promtail/config.yml
    networks: [loki]

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
      - GF_AUTH_ANONYMOUS_ENABLED=true          # REMOVE for production
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Admin        # REMOVE for production
      - GF_FEATURE_TOGGLES_ENABLE=alertingSimplifiedRouting,alertingQueryAndExpressionsStepMode
    entrypoint:
      - sh
      - -euc
      - |
        mkdir -p /etc/grafana/provisioning/datasources
        cat <<EOF > /etc/grafana/provisioning/datasources/ds.yaml
        apiVersion: 1
        datasources:
          - name: Loki
            type: loki
            access: proxy
            orgId: 1
            url: http://loki:3100
            basicAuth: false
            isDefault: true
            version: 1
            editable: false
        EOF
        /run.sh
    ports:
      - "3000:3000"
    networks: [loki]
```

Bring up:

```bash
docker compose up -d
# Loki → http://localhost:3100
# Grafana → http://localhost:3000 (anonymous Admin — sandbox only)
```

Then in Grafana: **Explore → Datasource Loki → LogQL queries**.

## Minimal `loki-config.yaml` (single-binary, filesystem storage)

```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  instance_addr: 127.0.0.1
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2025-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  retention_period: 720h    # 30 days

compactor:
  working_directory: /loki/compactor
  delete_request_store: filesystem
  retention_enabled: true

ruler:
  alertmanager_url: http://localhost:9093
```

## Install — Helm (Kubernetes, OSS users after March 2026)

```bash
helm repo add grafana-community https://grafana-community.github.io/helm-charts   # post-fork
helm repo update
helm install loki grafana-community/loki -n loki --create-namespace \
  --values values.yaml
```

Before the Mar 2026 fork, use:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki -n loki --create-namespace --values values.yaml
```

See <https://grafana.com/docs/loki/latest/setup/install/helm/> for values.yaml examples (scalable vs monolithic mode).

## LogQL basics (query language)

```logql
# All logs from the 'nginx' job
{job="nginx"}

# Error-level logs in last 5 minutes, filter for 500s
{job="nginx", level="error"} |= "500"

# Count error rate per minute
sum(rate({job="nginx", level="error"}[5m])) by (instance)

# Structured log extraction
{job="app"} | json | http_status >= 500

# Regex filter
{job="nginx"} |~ "api/v1/.*[4-5][0-9][0-9]"
```

Docs: <https://grafana.com/docs/loki/latest/query/>.

## Sending logs to Loki

Options, in order of preference:

1. **Alloy** — next-gen agent, convergence of Promtail + Grafana Agent + others.
2. **Promtail** — feature-complete, still maintained for bug fixes.
3. **Docker Logging Driver** (<https://grafana.com/docs/loki/latest/send-data/docker-driver/>) — no agent; Docker pushes directly.
4. **Fluent Bit** (with loki plugin) — good for edge / IoT.
5. **Vector** (<https://vector.dev>) — alternative agent with Loki sink.
6. **OpenTelemetry Collector** — OTLP → Loki receiver.
7. **Direct HTTP API** (`POST /loki/api/v1/push`) — for custom apps.

## Data layout

### Monolithic (filesystem storage)

| Path | Content |
|---|---|
| `/loki/chunks/` | Compressed log chunks |
| `/loki/index/` | Label index files |
| `/loki/rules/` | Recording + alerting rules |
| `/loki/compactor/` | Compactor state |

### Object-storage mode (production)

Everything above except `/loki/chunks/` + `/loki/index/` lives in S3 / GCS / Azure / MinIO. Loki itself is stateless.

**Backup**: for object-storage mode, enable versioning on the bucket + cross-region replication. For filesystem, rsync `/loki/` while paused (chunks are immutable once flushed).

## Retention + deletion

Set `limits_config.retention_period: 720h` for 30-day retention. `compactor` is the component that actually deletes old data based on retention. Without the compactor running + `retention_enabled: true`, data lives forever.

Per-tenant retention via `overrides.yaml` for multi-tenant deploys.

## Upgrade procedure

```bash
# Review release notes ALWAYS
# https://grafana.com/docs/loki/latest/setup/upgrade/
# https://github.com/grafana/loki/releases

# Docker Compose
docker compose pull
docker compose up -d

# Helm
helm repo update
helm upgrade loki grafana-community/loki -n loki --values values.yaml
```

Major version jumps (v2 → v3) have introduced schema changes. Upstream provides migration docs per release.

## Gotchas

- **Don't put high-cardinality data in labels.** Bad labels: `user_id`, `trace_id`, `request_path`, `session_id`. Good labels: `job`, `namespace`, `container`, `level`, `env`. A label with millions of unique values = Loki chokes. This is the #1 mistake new users make. Use log content for high-cardinality attributes; filter with `|=` at query time.
- **Every unique label combination = one stream.** 1000s of streams OK; 100Ks of streams = performance cliff. Monitor `loki_ingester_streams_created_total`.
- **Queries without label filters are slow.** `{} |= "error"` scans ALL data. `{job="nginx"} |= "error"` is fast. Always anchor queries on labels.
- **`auth_enabled: true` requires X-Scope-OrgID header on every request.** Multi-tenant mode. Alloy/Promtail config must include tenant ID. Single-tenant deploys should set `false`.
- **Object-storage latency hits cold queries.** S3 GET latency is ~50-100ms per chunk. A query over a week of data fetching 10K chunks = 500-1000 seconds without query parallelism. Tune `querier.max_concurrent` + `query_scheduler` for production.
- **Ingesters are stateful** (hold recent chunks in memory before flushing). If you lose an ingester mid-flush, you lose the unflushed data. Replication factor 3 in production; use WAL to survive restarts.
- **Loki doesn't dedupe across replicas** until chunks are flushed. During the "in-memory window" (default ~1h), you may see duplicate log lines in queries from replicated ingesters. Acceptable at scale.
- **Schema changes require `schema_config` entries with `from:` dates.** Don't modify existing schema entries; ADD a new one with a future `from:` date. Loki reads old data with old schema, new data with new.
- **`compactor` is NOT optional in production.** Without it, old index files accumulate forever. Enable + give it resources.
- **Retention deletes data async.** Setting `retention_period: 30d` doesn't instantly delete 31-day-old data; the compactor does it on schedule. Don't rely on retention for compliance-grade deletion; use explicit delete APIs.
- **Filesystem storage is NOT for multi-node.** Only works for single-binary. For HA, object storage is mandatory.
- **Docker logging driver can fill up the Loki endpoint** on high-log-volume containers. Set rate limits in Loki's `limits_config` + configure Docker driver with `max-size` / `max-file`.
- **Grafana query preview "limit" is per-panel default 1000 lines.** Set higher in the query if you need full log volume.
- **`schema v13` (TSDB) is the current recommended schema.** Older schemas (v11, v12, BoltDB) still work but are deprecated. Migrate when upgrading.
- **Memory footprint** can surprise you — ingesters hold ~hours of recent logs in-memory. 1 GB per ingester per ~1K streams is a rough rule of thumb.
- **Rate-limit your ingest.** `limits_config.ingestion_rate_mb` + `ingestion_burst_size_mb`. Without these, a noisy app can DoS your Loki.
- **Alloy vs Promtail**: you can mix — existing Promtail deployments keep working. Don't rush to migrate unless you want new Alloy features.
- **LogQL is not SQL.** It's label selectors + pipeline stages. Teaching team members "just like Elasticsearch but different" usually fails; point them at the LogQL docs.
- **Helm chart fork in March 2026** — OSS users must switch repo source. Watch the GitHub issue #20705 for timing.

## Links

- Upstream repo: <https://github.com/grafana/loki>
- Docs (current): <https://grafana.com/docs/loki/latest/>
- Docs (next / main branch): <https://grafana.com/docs/loki/next/>
- Installation: <https://grafana.com/docs/loki/latest/setup/install/>
- Helm install: <https://grafana.com/docs/loki/latest/setup/install/helm/>
- Helm charts (OSS — from Mar 2026): <https://github.com/grafana-community/helm-charts>
- Upgrade guide: <https://grafana.com/docs/loki/latest/setup/upgrade/>
- LogQL reference: <https://grafana.com/docs/loki/latest/query/>
- API reference: <https://grafana.com/docs/loki/latest/reference/loki-http-api/>
- Docker driver: <https://grafana.com/docs/loki/latest/send-data/docker-driver/>
- Alloy: <https://github.com/grafana/alloy>
- Releases: <https://github.com/grafana/loki/releases>
- Community forum: <https://community.grafana.com/c/grafana-loki/>
- Slack: <https://slack.grafana.com> (channel `#loki`)
