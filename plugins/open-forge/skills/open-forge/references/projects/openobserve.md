# OpenObserve (O2)

Open-source, cloud-native observability platform for logs, metrics, traces, dashboards, alerts, and Real User Monitoring (RUM). Rust-based single binary with 140x lower storage cost than Elasticsearch, using Parquet columnar storage on S3-compatible backends. Datadog/Splunk alternative. 14K+ GitHub stars. AGPL-3.0 (community) / commercial (enterprise). Upstream: <https://github.com/openobserve/openobserve>. Docs: <https://openobserve.ai/docs>.

## Compatible install methods

Verified against upstream README at <https://github.com/openobserve/openobserve#getting-started>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Binary (single file) | Download from GitHub releases, run `./openobserve` | ✅ | Quickest local start. Single binary, no dependencies. |
| Docker | `docker run -d -p 5080:5080 public.ecr.aws/zinclabs/openobserve:latest` | ✅ | Containerized single-node. |
| Docker Compose | Community compose files in docs | ✅ | Multi-service local setup. |
| Helm (Kubernetes) | <https://github.com/openobserve/openobserve-helm-chart> | ✅ | Production HA deployment. |
| OpenObserve Cloud | <https://cloud.openobserve.ai> | ✅ (hosted) | Free tier (200 GB/month ingestion). |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| admin_email | "Admin user email?" | Free-text | All |
| admin_password | "Admin password?" | Free-text (sensitive) | All |
| data_dir | "Local data directory (default: `/data`)?" | Free-text | Single-node |
| s3_bucket | "S3-compatible bucket name (for HA/cloud-native mode)?" | Free-text | HA / S3 backend |
| domain | "Domain for OpenObserve (e.g. `o2.example.com`)?" | Free-text | Production |

## Software-layer concerns

### Quick start (Docker)

```bash
docker run -d \
  --name openobserve \
  -v /data:/data \
  -p 5080:5080 \
  -e ZO_ROOT_USER_EMAIL="admin@example.com" \
  -e ZO_ROOT_USER_PASSWORD="changeme" \
  public.ecr.aws/zinclabs/openobserve:latest
```

Visit `http://localhost:5080` — default credentials from env vars above.

### Docker Compose (recommended)

```yaml
version: "3"
services:
  openobserve:
    image: public.ecr.aws/zinclabs/openobserve:latest
    restart: unless-stopped
    ports:
      - "5080:5080"
    volumes:
      - o2data:/data
    environment:
      ZO_DATA_DIR: "/data"
      ZO_ROOT_USER_EMAIL: "admin@example.com"
      ZO_ROOT_USER_PASSWORD: "changeme"
volumes:
  o2data:
```

### Key environment variables

| Variable | Purpose | Default |
|---|---|---|
| `ZO_ROOT_USER_EMAIL` | Admin user email | **Required** |
| `ZO_ROOT_USER_PASSWORD` | Admin password | **Required** |
| `ZO_DATA_DIR` | Local data storage path | `/data` |
| `ZO_HTTP_PORT` | HTTP port | `5080` |
| `ZO_GRPC_PORT` | gRPC port (for OTLP) | `5081` |
| `ZO_NODE_ROLE` | Node role in HA mode: `all`, `ingester`, `querier`, `compactor`, `router` | `all` |
| `ZO_S3_BUCKET_NAME` | S3 bucket for HA/cloud-native storage | (empty = local) |
| `ZO_S3_REGION_NAME` | S3 region | |
| `ZO_S3_ACCESS_KEY` | S3 access key | |
| `ZO_S3_SECRET_KEY` | S3 secret key | |
| `ZO_S3_SERVER_URL` | Custom S3-compatible endpoint (MinIO, Cloudflare R2, etc.) | |
| `ZO_META_STORE` | Metadata store: `sled` (local), `postgres`, `mysql`, `sqlite` | `sled` |
| `ZO_META_POSTGRES_DSN` | PostgreSQL DSN for metadata in HA mode | |
| `ZO_COMPACT_ENABLED` | Enable background compaction | `true` |
| `ZO_TELEMETRY` | Send anonymous telemetry to OpenObserve | `true` |

### Ingest data

**OpenTelemetry (recommended):**

```yaml
# otel-collector config
exporters:
  otlphttp:
    endpoint: http://o2.example.com:5080/api/default/
    headers:
      Authorization: "Basic <base64(email:password)>"
```

**Fluent Bit (logs):**

```ini
[OUTPUT]
  Name        http
  Host        o2.example.com
  Port        5080
  URI         /api/default/logs/_json
  Format      json
  HTTP_User   admin@example.com
  HTTP_Passwd changeme
```

**Direct HTTP API:**

```bash
curl -u admin@example.com:changeme \
  -H "Content-Type: application/json" \
  -d '[{"level":"info","message":"hello","service":"myapp"}]' \
  "http://localhost:5080/api/default/logs/_json"
```

### Ports

| Port | Service |
|---|---|
| `5080` | HTTP API + Web UI |
| `5081` | gRPC (OTLP traces/metrics) |

### Architecture (HA mode)

In High Availability mode, OpenObserve separates into independent scalable roles:

| Role | Function |
|---|---|
| `router` | Routes requests to correct node type |
| `ingester` | Receives and buffers incoming telemetry |
| `querier` | Executes search queries against Parquet files in S3 |
| `compactor` | Merges small Parquet files for query efficiency |
| `alert_manager` | Evaluates alert rules |

All roles connect to shared S3 storage and a shared metadata DB (PostgreSQL recommended).

## Upgrade procedure

```bash
docker pull public.ecr.aws/zinclabs/openobserve:latest
docker compose up -d
```

OpenObserve handles schema migrations automatically on startup.

## Gotchas

- **`ZO_ROOT_USER_EMAIL` / `ZO_ROOT_USER_PASSWORD` are required.** Without them the container won't start.
- **Default local storage is not suitable for HA.** Single-node uses local Parquet files. For HA, configure S3-compatible object storage.
- **Authentication is HTTP Basic by default.** Production deployments should use a reverse proxy with HTTPS. API tokens can be generated in the UI.
- **`ZO_TELEMETRY=true` by default.** Set to `false` to disable anonymous usage telemetry.
- **AGPL-3.0 license** — community edition. Using OpenObserve as part of a SaaS offering requires either AGPL compliance (open-sourcing your product) or a commercial license.
- **S3-compatible storage.** Works with AWS S3, MinIO, Cloudflare R2, GCS (with S3 compatibility), DigitalOcean Spaces, etc.
- **Ingest formats.** Supports JSON logs, OTLP (logs/metrics/traces), Prometheus remote write, Elasticsearch `_bulk` API (drop-in compatibility), Loki push API, Kinesis Firehose, and more.

## Links

- Upstream: <https://github.com/openobserve/openobserve>
- Docs: <https://openobserve.ai/docs>
- Quick start: <https://openobserve.ai/docs/quickstart/>
- Environment variables: <https://openobserve.ai/docs/environment-variables/>
- HA deployment: <https://openobserve.ai/docs/ha_deployment/>
- Helm chart: <https://github.com/openobserve/openobserve-helm-chart>
- OpenObserve Cloud: <https://cloud.openobserve.ai>
