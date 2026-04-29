---
name: influxdb-project
description: InfluxDB recipe for open-forge. MIT/Apache-2.0 time-series database — THREE active versions as of 2026 (v1.x InfluxQL+TSM, v2.x Flux+InfluxQL+TSM, v3 Core SQL+InfluxQL+Parquet+DataFusion). Pick carefully — they're NOT drop-in compatible. v3 Core is the current GA (since April 2025), diskless architecture with object storage, DataFusion query engine. v2 still widely deployed, uses Flux + TSM storage. v1 legacy but supported. Covers version-selection decision tree, Docker + binary installs for all three, common setup flows, and the write-path/query-path compatibility matrix between versions.
---

# InfluxDB

MIT-or-Apache-2.0 open-source time-series database. Upstream: <https://github.com/influxdata/influxdb>. Docs: <https://docs.influxdata.com>. Company: InfluxData.

Purpose-built for high-volume time-series data: IoT sensors, server/application monitoring, network telemetry, financial market data, behavioral analytics. Optimized for fast ingest and quick point-in-time queries.

## ⚠️ THREE versions, pick carefully

As of 2026, the upstream repo hosts three concurrently-maintained versions on separate branches:

| Version | Branch | Query Languages | Storage | Write API | Status |
|---|---|---|---|---|---|
| **v3 Core** | `main` | SQL, InfluxQL | Apache Parquet on object storage or local disk | Line protocol (v2 + v1 compat APIs) | GA since April 2025. **Recommended for new deployments.** |
| **v2.x** | `main-2.x` | Flux, InfluxQL | TSM (Time-Structured Merge tree) | Line protocol (+ v1 compat) | Still supported, widely deployed (Grafana ecosystem, Home Assistant, many exporters target v2). |
| **v1.x** | `master-1.x` | InfluxQL, Flux | TSM | Line protocol | Legacy. In maintenance mode. Use only if migrating away is too hard. |

**They are NOT drop-in compatible.** Upgrading from v1 → v2 or v2 → v3 requires planning:

- **v1 → v2**: Upgrade script converts data. Flux is new. InfluxQL still works for queries.
- **v2 → v3**: Flux is GONE in v3. If you use Flux, rewrite queries in SQL or InfluxQL before upgrading. Write path is backwards-compatible (v2 clients work against v3).

## Version decision tree

1. **New deployment, pick one:** → **v3 Core** (unless you need Flux)
2. **Existing v2 with non-trivial Flux queries:** → Stay on v2 until you've rewritten queries OR accept that v3 removes Flux.
3. **Existing v1, small dataset:** → Upgrade to v2 (InfluxDB Cloud or self-host), then plan v3 migration.
4. **Existing v1, large dataset or InfluxQL-heavy:** → Stay on v1 a while longer OR jump directly to v3 (also speaks InfluxQL).
5. **Want a managed service:** → InfluxDB Cloud (InfluxData's hosted product) is the upstream-preferred path.
6. **Need Flux specifically:** → v2.x. Flux is not coming back in v3.

This recipe covers all three, with v3 Core as the primary.

## Compatible install methods

| Method | Upstream | First-party? | v1 / v2 / v3 | When to use |
|---|---|---|---|---|
| Docker image (official) | Docker Hub: `influxdb` | ✅ | all 3 | Most self-hosters. Pick tag carefully. |
| Debian / RPM packages | <https://portal.influxdata.com/downloads/> | ✅ | all 3 | Bare-metal Linux. |
| Tarball binaries | Same portal | ✅ | all 3 | Any Linux / macOS. |
| Homebrew | `brew install influxdb` | ⚠️ Community-curated | v2 (primarily) | macOS quick install. |
| Kubernetes Helm | <https://github.com/influxdata/helm-charts> | ✅ | v2 + v3 | K8s deployments. |
| InfluxDB Cloud | <https://cloud2.influxdata.com> | ✅ paid | v3 (hosted) | Managed service — recommended by upstream for production. |
| InfluxDB 3 Enterprise | Commercial | Paid | v3 enterprise | Closed-source features: clustering, enterprise support. |

## Image tags (Docker)

| Tag | Version |
|---|---|
| `influxdb:3-core` / `influxdb:3.x.y-core` | **v3 Core** (recommended) |
| `influxdb:3-enterprise` | v3 Enterprise (paid) |
| `influxdb:2` / `influxdb:2.x.y` | v2.x |
| `influxdb:1.11` | v1.11 (latest v1) |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "InfluxDB version?" | `AskUserQuestion`: `v3-core (recommended)` / `v2.x` / `v1.x (legacy)` | Drives section. |
| preflight | "Install method?" | `AskUserQuestion`: `docker` / `deb-rpm` / `tarball` / `helm` | Drives commands. |
| db | "Organization name?" | Free-text (v2 / v3) | Required on first-run setup. v1 doesn't have orgs. |
| db | "Initial bucket/database name?" | Free-text | `metrics`, `telegraf`, etc. v3 uses "database"; v2 uses "bucket"; v1 uses "database". |
| db | "Retention period?" | e.g. `30d`, `90d`, `infinite` | Sets data deletion policy. |
| admin | "Admin username + password?" | Free-text (sensitive) | Required on first-run setup. |
| admin | "API token name?" | Free-text | v2/v3 use tokens, not user/pass, for API calls. |
| storage | "Data directory?" | Default `/var/lib/influxdb` (v1) or `/var/lib/influxdb2` (v2) or `/var/lib/influxdb3` (v3) | Bind-mount this; it's where data lives. |
| storage-v3 | "Object storage backend for v3?" | `AskUserQuestion`: `local-disk` / `s3` / `gcs` / `azure-blob` | v3's signature feature: diskless-capable. |
| network | "HTTP port?" | Default `8086` (v1/v2), `8181` (v3) | |

## Install — v3 Core (Docker)

```yaml
# compose.yaml
services:
  influxdb3:
    image: influxdb:3-core                       # pin a minor version in prod
    container_name: influxdb3
    restart: unless-stopped
    ports:
      - "8181:8181"                              # HTTP (writes + queries)
    environment:
      INFLUXDB3_OBJECT_STORE: file                # Options: file, s3, gcs, azure
      INFLUXDB3_DB_DIR: /var/lib/influxdb3
      # S3 example:
      # INFLUXDB3_OBJECT_STORE: s3
      # INFLUXDB3_BUCKET: my-influx-bucket
      # AWS_ACCESS_KEY_ID: ...
      # AWS_SECRET_ACCESS_KEY: ...
      # AWS_DEFAULT_REGION: us-east-1
    volumes:
      - ./influxdb3-data:/var/lib/influxdb3
    command: >
      influxdb3 serve
      --node-id=host01
      --object-store=file
      --data-dir=/var/lib/influxdb3
```

### Write data (line protocol, v2-compatible API)

```bash
curl -X POST 'http://localhost:8181/api/v2/write?bucket=mydb&precision=s' \
  -H 'Authorization: Bearer <token>' \
  --data-raw 'temperature,room=kitchen value=22.4 1762524900'
```

### Query SQL

```bash
curl 'http://localhost:8181/api/v3/query_sql?db=mydb&q=SELECT+*+FROM+temperature+WHERE+time+>+now()-1h'
```

### InfluxQL (v1-compat)

```bash
curl 'http://localhost:8181/api/v3/query_influxql?db=mydb&q=SELECT+mean(value)+FROM+temperature+WHERE+time+>+now()-1h+GROUP+BY+room'
```

## Install — v2.x (Docker)

```yaml
# compose.yaml
services:
  influxdb2:
    image: influxdb:2.7                          # pin exact version
    container_name: influxdb2
    restart: unless-stopped
    ports:
      - "8086:8086"
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: admin
      DOCKER_INFLUXDB_INIT_PASSWORD: strongadminpass
      DOCKER_INFLUXDB_INIT_ORG: myorg
      DOCKER_INFLUXDB_INIT_BUCKET: metrics
      DOCKER_INFLUXDB_INIT_RETENTION: 90d
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: my-super-secret-token
    volumes:
      - ./influxdb2-data:/var/lib/influxdb2
      - ./influxdb2-config:/etc/influxdb2
```

First boot runs setup automatically with those env vars. Web UI: `http://<host>:8086/`.

### CLI setup (alternative to env-var auto-setup)

```bash
docker exec -it influxdb2 influx setup \
  --username admin \
  --password strongadminpass \
  --org myorg \
  --bucket metrics \
  --retention 90d \
  --force
```

## Install — v1.x (Docker, legacy)

```yaml
services:
  influxdb1:
    image: influxdb:1.11
    container_name: influxdb1
    restart: unless-stopped
    ports:
      - "8086:8086"
    environment:
      INFLUXDB_DB: mydb
      INFLUXDB_HTTP_AUTH_ENABLED: 'true'
      INFLUXDB_ADMIN_USER: admin
      INFLUXDB_ADMIN_PASSWORD: strongadminpass
      INFLUXDB_USER: telegraf
      INFLUXDB_USER_PASSWORD: telegrafpass
    volumes:
      - ./influxdb1-data:/var/lib/influxdb
```

## Ingestion with Telegraf

Telegraf (InfluxData's agent) is the typical data collector. One config, all versions of InfluxDB:

```toml
# telegraf.conf
[[outputs.influxdb_v2]]       # works with v2 AND v3
  urls = ["http://influxdb:8086"]    # or :8181 for v3
  token = "$INFLUX_TOKEN"
  organization = "myorg"
  bucket = "metrics"

[[inputs.cpu]]
  percpu = true
  totalcpu = true
[[inputs.mem]]
[[inputs.disk]]
```

Run: `telegraf --config telegraf.conf`.

## Visualization

- **InfluxDB 2.x** has a built-in dashboard UI. Basic but functional.
- **InfluxDB 3 Core** no longer ships the 2.x-style UI (as of writing). Use Grafana.
- **Grafana** is the de-facto standard. Add InfluxDB as a data source (pick v1-InfluxQL / v2-Flux / v3-SQL).

## Data layout

### v3 Core

| Path | Content |
|---|---|
| `INFLUXDB3_DB_DIR` | Write-ahead log + cache. Object store holds Parquet files. |
| Object store (file / S3 / GCS / Azure) | Persistent Parquet files. |

With S3 as object store: container disk is nearly empty; all real data is in S3. This is v3's diskless architecture selling point.

### v2

| Path | Content |
|---|---|
| `/var/lib/influxdb2/` | BoltDB (metadata), TSM (time series files), WAL |
| `/etc/influxdb2/` | Config file(s) |

### v1

| Path | Content |
|---|---|
| `/var/lib/influxdb/data/<db>/<rp>/<shard>/` | TSM files per shard |
| `/var/lib/influxdb/wal/` | Write-ahead log |
| `/var/lib/influxdb/meta/` | Metadata store |

## Backup / restore

### v3

```bash
# v3 uses object store — back up the S3 bucket OR rsync the local data dir
# For local: stop InfluxDB, rsync the data dir
# For S3: S3 versioning / cross-region replication / periodic snapshots
```

### v2

```bash
# Full backup
docker exec influxdb2 influx backup /var/lib/influxdb2/backup --token <admin-token>
# Then copy /var/lib/influxdb2/backup out

# Restore
docker exec influxdb2 influx restore /var/lib/influxdb2/backup --token <admin-token>
```

### v1

```bash
docker exec influxdb1 influxd backup -portable /backups
# Copy /backups out
docker exec influxdb1 influxd restore -portable /backups
```

## Upgrade procedure

### Within same major version (v2 → v2)

```bash
docker compose pull
docker compose up -d
# InfluxDB migrates schema automatically on boot
```

### v1 → v2

Use `influxd upgrade`:

```bash
# Run v2 image with the upgrade command pointed at v1's data dir
docker run --rm \
  -v ./influxdb1-data:/var/lib/influxdb:ro \
  -v ./influxdb2-data:/var/lib/influxdb2 \
  -v ./influxdb2-config:/etc/influxdb2 \
  influxdb:2.7 influxd upgrade \
    --v1-dir /var/lib/influxdb \
    --engine-path /var/lib/influxdb2/engine \
    --bolt-path /var/lib/influxdb2/influxd.bolt \
    --configs-path /etc/influxdb2/configs \
    --org myorg \
    --username admin \
    --password strongadminpass \
    --retention 0 \
    --token <new-admin-token>
```

### v2 → v3

v3 accepts v2 write-protocol directly; point your Telegraf/clients at the v3 endpoint. For historical data migration: export from v2 (annotated CSV or Line Protocol) and import into v3. See <https://docs.influxdata.com/influxdb3/core/admin/upgrade/>.

**Flux queries do NOT work in v3.** Rewrite them in SQL or InfluxQL.

## Gotchas

- **THREE versions with different query languages, APIs, and storage engines** is genuinely confusing. Write down which version you're on; it affects every doc search, every client config, every Grafana panel.
- **v3 removes Flux.** This is a big deal for shops with Flux-heavy dashboards. Plan the query rewrite before upgrading.
- **v2 setup is one-shot.** `DOCKER_INFLUXDB_INIT_MODE=setup` only runs ONCE; subsequent starts skip setup. If it fails partway, you may end up with a half-configured DB; delete the data volume and start over.
- **Admin tokens are shown ONCE (v2/v3).** If you don't save `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` on first boot, you'll need to regenerate it via CLI. Store it in a secret manager.
- **Retention policies (v1/v2) / "database" retention (v3) delete data forever.** A mistyped `1d` where you meant `1000d` = data loss. Test on a throwaway instance first.
- **Port 8086 is universal but overloaded.** v1, v2, v3 (v2-compat endpoints) all listen on 8086 by default. v3's native endpoint is 8181. If running multiple versions on one host, map to different external ports.
- **TSM (v1/v2) doesn't love cardinality explosions.** Adding a tag with unique per-measurement values (like `user_id` with millions of users as a tag) creates a cardinality explosion that grinds TSM to a halt. Use fields for high-cardinality data, not tags. v3 handles cardinality much better.
- **v3's "diskless" = S3 latency hits queries.** Pure cloud-object-store backend gives you unlimited storage for $0.023/GB/month, but queries must fetch Parquet files. Cold queries on cold data are slower than v2 on local disk. Use cache sizing + local disk hot tier.
- **Write compatibility ≠ query compatibility.** v3 accepts v2 writes fine; v2 queries from Grafana using Flux will NOT work against v3.
- **`influx` CLI vs `influxd` daemon.** `influx` is the client; `influxd` is the server. Common confusion in docs.
- **Clustering (HA) is enterprise-only in v3.** OSS v3 is single-node. For HA, use InfluxDB 3 Enterprise or InfluxDB Cloud.
- **v1 is end-of-life-ish.** Still released for bugfixes but don't build new systems on it.
- **Home Assistant ships the `influxdb` component for v1 + v2.** For HA with v3, use the v2-compat write API (it works). Native v3 HA integration may still be community-maintained.
- **Grafana data source for v3 is "InfluxDB" but set to SQL mode.** Grafana's InfluxDB plugin has a mode selector — pick SQL for v3 Core, Flux for v2, InfluxQL for v1 or InfluxQL-mode v3.
- **Authentication in v1 is OFF by default.** Ensure `INFLUXDB_HTTP_AUTH_ENABLED=true` before exposing a v1 instance anywhere non-trivial.
- **Line protocol tag limits.** Tag keys + values are strings only. Numeric data goes in fields. Don't store timestamps as fields — use the line protocol timestamp (last column).

## Links

- Upstream repo (all versions): <https://github.com/influxdata/influxdb>
- v3 Core branch: <https://github.com/influxdata/influxdb/tree/main>
- v2 branch: <https://github.com/influxdata/influxdb/tree/main-2.x>
- v1 branch: <https://github.com/influxdata/influxdb/tree/master-1.x>
- Docs portal: <https://docs.influxdata.com>
- v3 Core docs: <https://docs.influxdata.com/influxdb3/core/>
- v2 docs: <https://docs.influxdata.com/influxdb/v2/>
- v1 docs: <https://docs.influxdata.com/influxdb/v1/>
- Downloads: <https://portal.influxdata.com/downloads/>
- Docker Hub: <https://hub.docker.com/_/influxdb>
- Helm charts: <https://github.com/influxdata/helm-charts>
- Telegraf: <https://github.com/influxdata/telegraf>
- Line protocol: <https://docs.influxdata.com/influxdb/cloud-serverless/reference/syntax/line-protocol/>
- Flux (v2 language): <https://github.com/influxdata/flux>
- Community: <https://community.influxdata.com>
- Discord: <https://discord.gg/vZe2w2Ds8B>
