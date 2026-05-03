---
name: Graylog (Open)
description: "Centralized log management platform — collect, parse, search, alert on logs from servers, apps, network devices. Syslog/GELF/Beats/Kafka inputs; Elasticsearch/OpenSearch backend; MongoDB metadata. Web UI for search, dashboards, alerts, pipelines. SSPL-licensed Open Edition; paid Enterprise tier."
---

# Graylog Open

Graylog is a mature, centralized **log management platform** — collect logs from Linux/Windows servers, apps, network devices, cloud services; parse + enrich them; search via a fast web UI; build dashboards; define alerts; stream to archive. Think "Splunk but OSS-ish" or "the UI/alerting layer on top of Elasticsearch for logs."

> **License note (read first):** Graylog Open moved to **SSPL** (Server Side Public License) — **not an OSI-approved open-source license**. You can self-host freely; re-offering Graylog-as-a-service to third parties triggers source-disclosure of your "service stack." Most self-hosters are fine; re-hosters need legal review. Confirm current license at <https://www.mongodb.com/licensing/server-side-public-license>.

Features (Open Edition):

- **Inputs**: Syslog (UDP/TCP/TLS), GELF (native Graylog format), Beats (Filebeat/Metricbeat/Winlogbeat), Kafka, AWS CloudTrail/Kinesis, HTTP JSON, Raw TCP/UDP
- **Extractors + pipelines** — parse raw messages into structured fields
- **Search** — Lucene-style query, time-ranged, saved searches
- **Dashboards** — widgets for charts, counts, tables
- **Alerts** — conditions + notification channels (email, webhook, Slack, PagerDuty)
- **Streams** — route messages into logical buckets (app=nginx, severity=error) for role-based access + separate retention
- **User/role management** — LDAP, OIDC, local
- **Content packs** — shareable input + parser + dashboard bundles
- **API** — REST
- **Retention** — archive to tape/S3/file (Enterprise for auto-archival)

Paid **Graylog Enterprise** / **Graylog Security** (SIEM-focused) adds: audit logging, archiving, reports, anomaly detection, correlation, threat intel, team collab features.

- Upstream repo (server): <https://github.com/Graylog2/graylog2-server>
- Website: <https://www.graylog.org/>
- Docs: <https://docs.graylog.org>
- Docker Hub: <https://hub.docker.com/r/graylog/graylog>
- Community: <https://community.graylog.org>

## Architecture in one minute

Graylog is **three moving parts**:

1. **Graylog server** (Java) — ingestion, processing pipelines, web UI, REST API
2. **MongoDB** — stores config, users, dashboards, stream rules (NOT log data)
3. **OpenSearch** (or legacy Elasticsearch) — stores the **actual log messages** + indices

Logs flow: source → **input** (Graylog) → **pipelines/extractors** → indexed into OpenSearch → queryable via web UI.

- **OpenSearch is Graylog's current official storage backend** (since Graylog 5.x+). Elasticsearch 7.10 is the last supported ES version; going forward, use OpenSearch.
- **MongoDB 6/7+** for config storage (required).
- **Minimum RAM**: 4 GB total; real-world: 8+ GB for small setups, much more for high-throughput.
- **Disk**: scales with log volume + retention; OpenSearch is the disk hog.

## Compatible install methods

| Infra          | Runtime                                                      | Notes                                                        |
| -------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Single VM      | **Docker Compose (all-in-one)**                                 | **Fine for homelab / small prod**                                 |
| Single VM      | Ubuntu/RHEL `.deb`/`.rpm` packages                                 | Upstream-recommended for prod; systemd services                    |
| Multi-VM       | Graylog + OpenSearch cluster + MongoDB replica set                    | Production pattern                                                       |
| Kubernetes     | Helm charts (community + upstream "Graylog Operator" enterprise)           | Production-capable                                                            |
| Cloud managed  | Graylog Cloud (SaaS)                                                        | Upstream offering                                                                     |
| **Not recommended** | SQLite / no-MongoDB hacks                                              | Graylog requires MongoDB                                                                      |

## Inputs to collect

| Input           | Example                         | Phase      | Notes                                                             |
| --------------- | ------------------------------- | ---------- | ----------------------------------------------------------------- |
| Domain          | `logs.example.com`                | URL        | Reverse proxy with TLS                                                |
| Admin pass hash | sha256 of chosen password            | Bootstrap  | `echo -n "password" \| sha256sum` → set as `GRAYLOG_ROOT_PASSWORD_SHA2` |
| Password secret | random 64 chars                         | Crypto     | `GRAYLOG_PASSWORD_SECRET`; don't change after deploy                        |
| MongoDB         | `mongodb://mongo:27017/graylog`            | DB         | v6/7+                                                                             |
| OpenSearch      | `http://opensearch:9200`                      | DB         | v2+ recommended; ES 7.10 last-supported                                               |
| Syslog port     | 1514/udp+tcp (or 514, needs caps)                | Ingest     | Privileged port needs `setcap`                                                                 |
| GELF port       | 12201/udp (or tcp)                                  | Ingest     | Native Graylog format                                                                                |
| JVM heap        | `-Xms2g -Xmx2g`                                          | Tuning     | Set on Graylog AND OpenSearch containers                                                                          |

## Install via Docker Compose (minimal all-in-one)

```yaml
services:
  mongodb:
    image: mongo:7.0
    restart: unless-stopped
    volumes:
      - mongo-data:/data/db

  opensearch:
    image: opensearchproject/opensearch:2.14.0    # pin; match Graylog compatibility matrix
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - OPENSEARCH_JAVA_OPTS=-Xms2g -Xmx2g
      - action.auto_create_index=false
      - plugins.security.disabled=true
      - DISABLE_INSTALL_DEMO_CONFIG=true
    ulimits:
      memlock: { soft: -1, hard: -1 }
      nofile:  { soft: 65536, hard: 65536 }
    volumes:
      - opensearch-data:/usr/share/opensearch/data

  graylog:
    image: graylog/graylog:6.3                     # pin to a specific version
    restart: unless-stopped
    depends_on: [mongodb, opensearch]
    environment:
      GRAYLOG_PASSWORD_SECRET: <64-random-chars>
      GRAYLOG_ROOT_PASSWORD_SHA2: <sha256-of-admin-password>
      GRAYLOG_HTTP_EXTERNAL_URI: https://logs.example.com/
      GRAYLOG_ELASTICSEARCH_HOSTS: http://opensearch:9200
      GRAYLOG_MONGODB_URI: mongodb://mongodb:27017/graylog
    ports:
      - "9000:9000"       # web UI
      - "1514:1514/udp"    # syslog
      - "1514:1514/tcp"
      - "12201:12201/udp"  # GELF
      - "12201:12201/tcp"

volumes:
  mongo-data:
  opensearch-data:
```

Generate the password SHA: `echo -n "yourpassword" | sha256sum | awk '{print $1}'`.

Boot, wait ~60s for OpenSearch + Graylog to settle, browse `https://logs.example.com` → log in as `admin`.

## First boot

1. Log in as `admin`
2. **System → Inputs** → launch "Syslog UDP" on `0.0.0.0:1514` → save
3. Send a test log: `logger -n <host> -P 1514 "hello graylog"` → appears in Search
4. Create a **Stream** (e.g., "nginx errors") with rules (`source matches ^web`, `level=ERROR`)
5. Create **Dashboard** → add widgets (count over time, top fields, heatmap)
6. Create **Alert** → condition on the stream → notification (webhook/email/Slack)
7. **System → Users & Roles** → create per-team users; assign streams

## Scaling path

- **Small (10-100 GB/day logs)**: single-node Compose works.
- **Medium (100 GB - 1 TB/day)**: 3-node OpenSearch cluster, 1-2 Graylog nodes, MongoDB 3-member replica set.
- **Large (>1 TB/day)**: dedicated OpenSearch ingest/hot/warm/cold tiers, multi-Graylog behind LB, Kafka buffer in front.

## Data & config layout

- **Graylog**: stateless beyond MongoDB; config mostly in web UI
- **MongoDB** volume: users, streams, dashboards, inputs, extractors, pipelines
- **OpenSearch** volume: the actual log data (by far the biggest)
- Logs age out per index retention rules (configure in System → Indices)

## Backup

```sh
# MongoDB (CRITICAL — all config + users)
docker exec graylog-mongodb mongodump --archive=/tmp/mongo.dump
docker cp graylog-mongodb:/tmp/mongo.dump ./mongo-$(date +%F).dump

# OpenSearch (the logs themselves)
# Use Snapshot + Restore to S3 or a mounted volume
# https://opensearch.org/docs/latest/tuning-your-cluster/availability-and-recovery/snapshots/snapshot-restore/
```

Archiving old logs is a paid-Enterprise feature; community workaround = snapshot to S3 + purge old indices.

## Upgrade

1. Releases: <https://github.com/Graylog2/graylog2-server/releases>.
2. **Check compatibility matrix** — Graylog version ↔ OpenSearch/Elasticsearch version ↔ MongoDB version. Going out of bounds = unsupported.
3. **Back up MongoDB + take OpenSearch snapshot** before upgrade.
4. Minor upgrades: bump image tag, `up -d`.
5. Major upgrades (4.x → 5.x → 6.x): follow per-release upgrade notes; sometimes requires index-set migrations, re-computation, or ES→OpenSearch migration (5.0 → 5.2 was notable).
6. MongoDB major upgrades: follow Mongo's own 1-version-at-a-time upgrade path.

## Gotchas

- **SSPL license** — Graylog moved from GPL-3.0 to SSPL around 4.x. Self-hosting for your org = fine. Re-offering as a service = legal review. This is the same license tactic MongoDB uses.
- **Enterprise features locked**: audit log, archiving, reporting, correlation, anomaly detection, team-scoped admin — all **Enterprise**. Open is full-featured-enough for most homelabs + small orgs but know the line.
- **OpenSearch vs Elasticsearch**: since Graylog 5.x+, OpenSearch is the preferred backend. Elasticsearch 7.10 is the last supported ES version. Do not use ES 7.11+ or 8.x — not supported.
- **JVM tuning** — the default heap is tiny. Set `GRAYLOG_SERVER_JAVA_OPTS` and OpenSearch `OPENSEARCH_JAVA_OPTS` (typically 25-50% of host RAM, max 32 GB for ES/OS due to heap compressed-oops).
- **Memory mapping limits (Linux)** — OpenSearch requires `sysctl vm.max_map_count=262144` on the host. Otherwise OS fails to start.
- **MongoDB auth not enabled by default in the Compose example** — enable Mongo auth for production.
- **Index templates + retention** — define up front: how many shards, how long to keep. Defaults are "one index per day, keep 20." Adjust in System → Indices.
- **Field types matter** — Graylog indexes into OpenSearch with dynamic field mappings. Mixing types (e.g., `response_time` sometimes int, sometimes string) breaks indices. Define index field types early.
- **Syslog priv port (514)** — binding 514 requires root / CAP_NET_BIND_SERVICE. Easier to use 1514 and have rsyslog/nginx forward.
- **High-volume production pattern**: put **Kafka** in front of Graylog as a buffer. Graylog reads from Kafka topics; ingestion doesn't fail during Graylog restarts/upgrades.
- **Pipelines are the real parsing layer** — extractors are simpler but less flexible. Invest in Pipeline + Rule syntax for serious parsing.
- **Content packs**: check <https://marketplace.graylog.org> for pre-made inputs + dashboards for common apps (nginx, MySQL, AWS, Windows).
- **GELF over UDP** drops messages under load. Prefer GELF/TCP/TLS or Kafka for reliability.
- **Windows logs** — use NXLog or Winlogbeat → Graylog (Beats input). Windows event XML parses well with a pipeline rule.
- **Not a SIEM by itself** — Graylog is log management. For full SIEM (correlation, threat intel, case management) you need Graylog Security (paid) or a different product (Wazuh, Security Onion, OpenSearch Security, Elastic Security).
- **Alerts noisy** — start with tight conditions + generous grace periods. A bad regex = thousands of pages at 3 AM.
- **Don't expose port 9000 publicly** — reverse proxy with TLS + strong auth (or VPN).
- **Graylog Cloud**: upstream SaaS if you don't want to operate it.
- **Alternatives worth knowing:**
  - **Grafana Loki** — log aggregation designed to pair with Grafana; label-based, simpler than ES (separate recipe)
  - **Elastic Stack (ELK/Elasticsearch + Kibana + Beats)** — Elasticsearch itself is now Elastic-2.0/SSPL; similar license story
  - **OpenSearch + OpenSearch Dashboards** — fork of ES + Kibana pre-relicense; Apache-2.0; can skip Graylog and go direct
  - **Wazuh** — SIEM + endpoint; built on OpenSearch (separate recipe)
  - **SigNoz** — OTel-native observability; logs + traces + metrics
  - **Quickwit** — modern log search; cloud-native; Apache-2.0
  - **VictoriaLogs** — fast, lightweight; from VictoriaMetrics folks
  - **Splunk** — commercial gold standard; expensive
  - **Choose Graylog if:** you want a full-featured OSS log-management UI on top of ES/OpenSearch with pipelines + alerts + dashboards.
  - **Choose Loki if:** you're Grafana-native and want label-based logs with lower TCO.
  - **Choose OpenSearch directly if:** you want max control and a custom UI.
  - **Choose Wazuh if:** SIEM + endpoint security is the real goal.

## Links

- Repo: <https://github.com/Graylog2/graylog2-server>
- Website: <https://www.graylog.org/>
- Docs: <https://docs.graylog.org>
- Install docs: <https://docs.graylog.org/docs/installing-graylog>
- Docker Hub: <https://hub.docker.com/r/graylog/graylog>
- Compatibility matrix: <https://go2docs.graylog.org/current/downloading_and_installing_graylog/system_requirements.htm>
- Marketplace (content packs): <https://marketplace.graylog.org>
- Community forum: <https://community.graylog.org>
- Releases: <https://github.com/Graylog2/graylog2-server/releases>
- Graylog Cloud: <https://graylog.org/products/graylog-cloud/>
- License (SSPL): <https://www.mongodb.com/licensing/server-side-public-license>
- OpenSearch docs: <https://opensearch.org/docs/>
