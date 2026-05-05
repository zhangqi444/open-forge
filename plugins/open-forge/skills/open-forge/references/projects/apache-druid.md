# Apache Druid

High-performance real-time analytics database designed for fast queries and high-concurrency ingestion. Druid excels at powering dashboards, ad-hoc analytics, and operational queries on large-scale event data — supporting streaming (Kafka/Kinesis) and batch (S3, HDFS, local) ingestion.

**Official site:** https://druid.apache.org/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Official multi-container compose for quickstart |
| Kubernetes | druid-operator (Helm) | Official Kubernetes operator (`apache/druid-operator`) |
| Cloud (AWS/GCP/Azure) | EC2/GCE VMs | Multi-node cluster with S3/GCS deep storage |
| Single machine | Docker Compose (nano-quickstart) | Minimal local dev/test setup |

---

## Inputs to Collect

### Phase 1 — Planning
- Deployment scale: single-machine quickstart or multi-node cluster
- Deep storage: local (quickstart only) or S3/GCS/Azure Blob (production)
- Metadata store: Derby (quickstart) or PostgreSQL/MySQL (production)
- Expected ingestion rate and query concurrency

### Phase 2 — Deployment
- ZooKeeper connection string (bundled in compose for quickstart)
- PostgreSQL credentials for metadata store (production)
- Deep storage bucket name and credentials
- Heap sizes for each service (Coordinator, Broker, Historical, MiddleManager, Router)

---

## Software-Layer Concerns

### Docker Compose (Quickstart)

```yaml
# Uses official distribution/docker/docker-compose.yml from the repo
services:
  postgres:
    image: postgres:17.6
    environment:
      POSTGRES_PASSWORD: FoolishPassword
      POSTGRES_USER: druid
      POSTGRES_DB: druid

  zookeeper:
    image: zookeeper:3.5.10

  coordinator:
    image: apache/druid:38.0.0
    command: coordinator
    env_file: environment
    depends_on: [zookeeper, postgres]
    ports: ["8081:8081"]

  broker:
    image: apache/druid:38.0.0
    command: broker
    env_file: environment
    ports: ["8082:8082"]

  historical:
    image: apache/druid:38.0.0
    command: historical
    env_file: environment
    ports: ["8083:8083"]

  middlemanager:
    image: apache/druid:38.0.0
    command: middleManager
    env_file: environment
    ports: ["8091:8091"]

  router:
    image: apache/druid:38.0.0
    command: router
    env_file: environment
    ports: ["8888:8888"]
```

Access the web console at `http://localhost:8888/unified-console.html`

### Quickstart

```bash
git clone https://github.com/apache/druid.git
cd druid/distribution/docker
docker compose up -d
```

### Key `environment` File Variables
| Variable | Purpose |
|----------|---------|
| `DRUID_SINGLE_NODE_CONF` | Use single-node config (nano, micro, small, medium, large, xlarge) |
| `druid_metadata_storage_type` | `postgresql` or `derby` |
| `druid_metadata_storage_connector_connectURI` | JDBC URI for metadata DB |
| `druid_storage_type` | `local`, `s3`, `google`, `azure` |
| `druid_storage_storageDirectory` | Local deep storage path |
| `druid_s3_bucket` | S3 bucket for deep storage |
| `druid_indexer_logs_type` | Where to store task logs (`s3`, `file`) |

### Services Overview
| Service | Port | Purpose |
|---------|------|---------|
| Router | 8888 | Web console + query routing |
| Coordinator | 8081 | Cluster management, segment assignment |
| Broker | 8082 | Query execution |
| Historical | 8083 | Stores and serves immutable segments |
| MiddleManager | 8091 | Ingestion task execution |

---

## Upgrade Procedure

```bash
# Docker: update image tag in compose, then:
docker compose pull && docker compose up -d
```

**Kubernetes:** `helm upgrade druid apache-druid/druid --version <new-version>`

Always review the [migration guide](https://druid.apache.org/docs/latest/operations/migration-guide.html) for breaking changes between major versions.

---

## Gotchas

- **ZooKeeper is required** for cluster coordination — do not skip it in production.
- **Deep storage must be shared** across Historical, MiddleManager, and Coordinator nodes (use S3/GCS in production, not local FS).
- **PostgreSQL/MySQL for metadata** — Derby (the default) is for quickstart only; use PostgreSQL in production.
- **Memory-intensive:** Each Druid process needs its own JVM heap. Plan for 4–8 GB total RAM minimum even for a small cluster.
- **Kafka integration** for real-time streaming — configure the Kafka Supervisor via the web console or REST API.
- **Security disabled by default** — enable TLS and Kerberos/LDAP auth for production deployments.

---

## References
- GitHub: https://github.com/apache/druid
- Official site: https://druid.apache.org/
- Docs: https://druid.apache.org/docs/latest/
- Docker Hub: https://hub.docker.com/r/apache/druid
- druid-operator (K8s): https://github.com/apache/druid-operator
- Docker quickstart: https://druid.apache.org/docs/latest/tutorials/docker.html
