---
name: Quickwit
description: Cloud-native distributed search + analytics engine for logs, traces, and events. Elasticsearch-compatible API, Jaeger/OpenTelemetry-native, schemaless, sub-second search directly on object storage (S3/GCS/Azure). Rust. AGPL-3.0 (commercial available).
---

# Quickwit

Quickwit is a modern, cloud-native alternative to Elasticsearch built specifically for **logs, traces, and events** (append-only telemetry data). The headline trick: it searches **directly against object storage** (S3 / GCS / Azure Blob) without needing local disks or shard replicas. That means:

- **Decoupled compute and storage** — add searchers/indexers independently; scale each for its workload
- **Cheap at rest** — S3 storage is pennies per GB; no 3× replica overhead
- **Stateless indexers + searchers** — lose a node → no data loss
- **Sub-second search on cloud storage** — via aggressive columnar indexing + `hot_cache`
- **Kubernetes-friendly** — no persistent volumes required for data (only metadata)

- **Elasticsearch-compatible API** — works with Elasticsearch/OpenSearch clients, Logstash, Fluentd, Vector, etc.
- **Jaeger-native** + **OpenTelemetry-native** — plug directly into distributed tracing + log pipelines
- **Grafana data source** — query logs + traces from Grafana
- **Multi-tenancy** — many indexes, partitioning
- **Retention policies** + **delete tasks** (for GDPR)
- **Distributed + HA** indexing (HA requires Kafka for ingest)
- **Schemaless** OR strict schema

- Upstream repo: <https://github.com/quickwit-oss/quickwit>
- Website: <https://quickwit.io>
- Docs: <https://quickwit.io/docs/>
- Install: <https://quickwit.io/docs/get-started/installation>
- Quickstart: <https://quickwit.io/docs/get-started/quickstart>
- Helm chart: <https://quickwit.io/docs/deployment/kubernetes/helm>
- Grafana data source: <https://github.com/quickwit-oss/quickwit-datasource>

## Architecture in one minute

Quickwit is decomposable; you can run it as one binary or split into roles:

- **Indexer** — ingests events (JSON lines, Kafka, Kinesis, Pulsar), builds immutable "splits" (columnar index files), uploads to object store
- **Searcher** — stateless; reads splits directly from object store + keeps a hot cache locally
- **Metastore** — stores split metadata (which splits exist, schema, time range). Backed by **PostgreSQL** (prod) or a file (single-node demo)
- **Control plane** — orchestrates indexers, manages splits, schedules merges
- **Ingester** — holds recent data before it's packed into splits

For demo: single `quickwit run` process serves all roles + uses local file metastore + local FS storage.

For prod: Kubernetes with 3-5 searchers + 2-3 indexers + Postgres metastore + S3 storage + Kafka for HA ingest.

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                                  |
| ----------- | ---------------------------------------------------- | ---------------------------------------------------------------------- |
| Single VM   | Docker (`quickwit/quickwit`)                           | Quickstart path                                                          |
| Single VM   | Native binary                                         | `curl -L https://install.quickwit.io | sh`                                |
| Kubernetes  | **Official Helm chart**                                | Production-recommended                                                    |
| Kubernetes  | Raw manifests + S3 + Postgres                          | More control                                                              |
| Bare-metal cluster | Systemd units per role                           | Run indexer, searcher, control plane separately                            |
| Managed     | Hostedby — community-run                               | No official SaaS (though commercial support exists)                         |

## Inputs to collect

| Input                      | Example                                       | Phase     | Notes                                                             |
| -------------------------- | --------------------------------------------- | --------- | ----------------------------------------------------------------- |
| Metastore URI              | `postgres://user:pw@host:5432/quickwit_metastore` or file path | Storage | Prod = Postgres; demo = file          |
| Default index storage      | `s3://my-bucket/quickwit/` or `file:///data/` | Storage   | Where splits live                                                   |
| Cluster ID / Node ID       | strings                                        | Config    | Identify node in cluster                                            |
| REST listen addr           | `0.0.0.0:7280`                                 | Network   | API + UI                                                             |
| gRPC listen addr           | `0.0.0.0:7281`                                 | Network   | Inter-node                                                          |
| Discovery mode             | `default` (gossip) or `static` (peer list)      | Cluster   | For multi-node setups                                                 |
| Kafka (optional for HA)    | brokers + topic                                 | Ingest    | Only path to HA indexing                                              |

## Install via Docker (single-node demo)

```sh
mkdir -p qwdata
docker run --rm -p 7280:7280 \
  -v $PWD/qwdata:/quickwit/qwdata \
  quickwit/quickwit:v0.8.2 \
  run
```

Open <http://localhost:7280> — the Quickwit UI.

Create an index:

```sh
curl -X POST http://localhost:7280/api/v1/indexes \
  -H "Content-Type: application/yaml" \
  --data-binary @- << 'EOF'
version: 0.7
index_id: stackoverflow
doc_mapping:
  field_mappings:
    - name: title
      type: text
    - name: body
      type: text
    - name: tags
      type: array<text>
    - name: creationDate
      type: datetime
      input_formats: [rfc3339]
      fast: true
  timestamp_field: creationDate
indexing_settings:
  commit_timeout_secs: 10
EOF
```

Ingest data:

```sh
curl -X POST http://localhost:7280/api/v1/stackoverflow/ingest \
  -H "Content-Type: application/x-ndjson" \
  --data-binary @stackoverflow.ndjson
```

Search:

```sh
curl "http://localhost:7280/api/v1/stackoverflow/search?query=%22distributed+tracing%22"
```

## Install via Kubernetes (production)

Use the [official Helm chart](https://quickwit.io/docs/deployment/kubernetes/helm):

```sh
helm repo add quickwit https://helm.quickwit.io
helm repo update
helm install quickwit quickwit/quickwit \
  --set searcher.replicas=3 \
  --set indexer.replicas=2 \
  --set config.metastore.postgres.host=my-postgres \
  --set config.storage.s3.bucket=my-bucket \
  --set config.storage.s3.region=us-east-1 \
  --set-string 'config.storage.s3.access_key_id=...' \
  --set-string 'config.storage.s3.secret_access_key=...'
```

## Data & config layout

On an indexer/searcher node:

- `/quickwit/qwdata/` — hot cache (searcher) + ingester queue buffer (indexer)
- `/quickwit/config/quickwit.yaml` — node config
- **Splits live in object storage** — not on the node

Metastore in Postgres:

- `indexes` table — per-index config
- `splits` table — metadata for every split

## Backup

```sh
# Metastore (the critical part)
pg_dump -h my-postgres -U quickwit quickwit_metastore | gzip > qw-metastore-$(date +%F).sql.gz

# Splits are in object storage — enable bucket versioning + cross-region replication
aws s3api put-bucket-versioning --bucket my-bucket --versioning-configuration Status=Enabled
```

Losing the metastore = splits still exist in S3 but you can't query them. **Metastore is the critical piece.** Losing splits = data loss.

## Upgrade

1. Releases: <https://github.com/quickwit-oss/quickwit/releases>. Active.
2. **v0.x era — expect breaking changes at minor versions.** Read release notes carefully.
3. Helm: `helm upgrade quickwit quickwit/quickwit --version <new>`.
4. Rolling upgrade: indexers first, then searchers, then control plane. Quickwit handles version skew reasonably.
5. Back up metastore before every upgrade.

## Gotchas

- **v0.x — API + config schema are NOT stable yet.** Pin versions + read release notes for minor bumps. Quickwit is production-grade at many orgs but the "1.0" milestone hasn't landed as of 2025.
- **Not a general-purpose search engine for documents** — it's optimized for **append-only time-series data** (logs, traces, events). If your use case is e-commerce product search or a knowledge base, use Elasticsearch/Meilisearch/Typesense instead.
- **Delete/update semantics are limited** — you can delete by query (for GDPR) but there's no UPDATE. Data is immutable once indexed.
- **HA indexing requires Kafka** (or Pulsar/Kinesis). Plain HTTP ingest isn't HA — if an indexer dies mid-ingest, the in-flight events may be lost. Use Kafka-based ingest for mission-critical telemetry.
- **Object storage latency matters** — searchers cache hot splits locally; first query on a cold split is slower than Elasticsearch. For consistently low latency, size the hot cache appropriately (few hundred GB of NVMe per searcher is common).
- **Metastore Postgres** is a single point of failure — use a managed HA Postgres (RDS, Cloud SQL) for prod.
- **Elasticsearch API compatibility is a subset** — most "index, search, bulk, aggregate" calls work; cluster-management calls typically don't. Test your specific client library.
- **Grafana integration** via <https://github.com/quickwit-oss/quickwit-datasource> is first-class; point at your Quickwit cluster and query logs + traces like you would with Loki/Elasticsearch.
- **AGPL-3.0 license** — strongest copyleft. Running Quickwit internally = no obligations. Offering Quickwit-as-a-service publicly = must share any modifications.
- **Commercial tier** (Quickwit Inc.) offers paid support + hosted SaaS. The OSS is fully-featured; enterprise contract is about support SLAs.
- **Schema** — can be schemaless (auto-detect field types) or strict. Schemaless is flexible but uses more storage; strict saves space + enables better aggregations.
- **Split merging** — indexer periodically merges small splits into bigger ones (like Elasticsearch segment merging). Tune `merge_policy` for your write rate.
- **Jaeger integration**: Quickwit can be a drop-in Jaeger backend — point Jaeger Query at Quickwit instead of Cassandra/Elasticsearch. Huge cost savings.
- **OTEL integration**: Quickwit natively accepts OTLP (OpenTelemetry Protocol) for logs + traces. Pair with OpenTelemetry Collector for the modern telemetry stack.
- **Retention** — per-index time-based retention; old splits auto-deleted from object storage + metastore.
- **Alternatives worth knowing:**
  - **Elasticsearch / OpenSearch** — mature, general-purpose, higher operating cost for telemetry
  - **Loki (Grafana Labs)** — logs-only, label-based (no full-text), simpler model
  - **VictoriaLogs** — logs-focused, similar S3-backed model, more ops-friendly
  - **ClickHouse + FriendlyArctic (for logs)** — columnar DB with SQL
  - **Signoz / SigNoz Cloud** — full APM on top of ClickHouse
  - **Jaeger + Cassandra** — traditional tracing backend
  - **Datadog / Honeycomb / Observe / Grafana Cloud** — commercial SaaS

## Links

- Repo: <https://github.com/quickwit-oss/quickwit>
- Website: <https://quickwit.io>
- Docs: <https://quickwit.io/docs/>
- Installation: <https://quickwit.io/docs/get-started/installation>
- Architecture: <https://quickwit.io/docs/overview/architecture>
- REST API: <https://quickwit.io/docs/reference/rest-api>
- Helm chart: <https://quickwit.io/docs/deployment/kubernetes/helm>
- Grafana data source: <https://github.com/quickwit-oss/quickwit-datasource>
- Jaeger integration: <https://quickwit.io/docs/distributed-tracing/plug-quickwit-to-jaeger>
- OTEL logs: <https://quickwit.io/docs/log-management/overview>
- Releases: <https://github.com/quickwit-oss/quickwit/releases>
- Docker Hub: <https://hub.docker.com/r/quickwit/quickwit>
- Discord: <https://discord.quickwit.io>
- Blog: <https://quickwit.io/blog/>
