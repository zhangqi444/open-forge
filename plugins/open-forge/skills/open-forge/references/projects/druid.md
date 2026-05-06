---
name: druid
description: Apache Druid recipe for open-forge. High-performance real-time analytics database — distributed, column-oriented, sub-second queries on streaming and batch data. Docker Compose install. Upstream: https://github.com/apache/druid
---

# Apache Druid

High-performance, distributed, column-oriented real-time analytics database. Designed for workflows where fast queries and ingest really matter — powering dashboards, operational queries, and high-concurrency workloads at scale.

13,985 stars · Apache-2.0

Upstream: https://github.com/apache/druid
Website: https://druid.apache.org
Docs: https://druid.apache.org/docs/latest/
Docker Hub: https://hub.docker.com/r/apache/druid

## What it is

Apache Druid provides a full real-time analytics stack:

- **Sub-second queries** — OLAP-style queries on billions of rows at low latency
- **Streaming and batch ingestion** — Native Kafka, Kinesis, S3, HDFS connectors
- **Column-oriented storage** — Compressed columnar format with bitmap indexing
- **DruidSQL** — Full SQL interface via HTTP and JDBC
- **Web console** — Point-and-click data loader, query workbench, cluster management
- **Horizontal scalability** — Add nodes to scale ingestion and query independently
- **Data roll-up** — Pre-aggregate at ingest time to reduce storage footprint
- **Kubernetes support** — Official druid-operator for K8s deployments

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker Compose | Multi-container | Coordinator, Broker, Historical, MiddleManager, Router + PostgreSQL + ZooKeeper |
| Kubernetes | Helm / druid-operator | See github.com/apache/druid-operator |
| Bare metal | Java 17 | Tarball install, requires ZooKeeper and metadata DB |

## Inputs to collect

### Phase 1 — Pre-install
- Deployment size (nano/small/large) — determines memory allocation
- Deep storage backend: local, S3, GCS, Azure, HDFS
- Metadata store: Derby (dev), PostgreSQL (prod), MySQL
- ZooKeeper connection string if using external ZK
- Expected data volume (affects broker/historical memory tuning)

### Phase 2 — Runtime config
- druid_zk_service_host — ZooKeeper host
- druid_metadata_storage_type — postgresql or mysql
- druid_metadata_storage_connector_connectURI — JDBC URL
- druid_metadata_storage_connector_user / password
- druid_storage_type — local, s3, google, azure
- druid_indexer_logs_type — log storage backend
- JAVA_OPTS / heap sizes per service

## Software-layer concerns

### Config paths
- /opt/druid/conf/druid/cluster/ — cluster config directory
- /opt/druid/var/ — runtime data, segments, task logs (mount as volume)
- /opt/shared/ — shared segment storage between historical and middlemanager

### Environment file
Druid Docker uses an environment file (not .env) at the compose root.
Key settings:
  DRUID_XMX=1g
  DRUID_XMS=1g
  druid_zk_service_host=zookeeper
  druid_metadata_storage_type=postgresql
  druid_metadata_storage_connector_connectURI=jdbc:postgresql://postgres:5432/druid
  druid_metadata_storage_connector_user=druid
  druid_metadata_storage_connector_password=FoolishPassword
  druid_storage_type=local
  druid_storage_storageDirectory=/opt/shared/segments
  druid_indexer_logs_type=file
  druid_indexer_logs_directory=/opt/shared/indexing-logs

### Services and ports
- Coordinator: 8081
- Broker: 8082
- Historical: 8083
- MiddleManager: 8091, 8100-8105
- Router (web console): 8888
- PostgreSQL: 5432 (internal)
- ZooKeeper: 2181 (internal)

Web console available at http://<host>:8888

## Docker Compose install

Requires an environment file at the compose root (see above). Services:

  postgres: image postgres:17.6, volume metadata_data:/var/lib/postgresql/data
  zookeeper: image zookeeper:3.5.10, port 2181
  coordinator: image apache/druid:38.0.0, port 8081, command coordinator
  broker: image apache/druid:38.0.0, port 8082, command broker
  historical: image apache/druid:38.0.0, port 8083, command historical
  middlemanager: image apache/druid:38.0.0, ports 8091 + 8100-8105, command middleManager
  router: image apache/druid:38.0.0, port 8888, command router

All Druid services share druid_shared volume and use env_file: environment.

Full compose: https://github.com/apache/druid/blob/master/distribution/docker/docker-compose.yml

## Upgrade procedure

1. Review release notes at https://druid.apache.org/downloads.html
2. Update image tag in docker-compose.yml
3. Stop services gracefully: docker compose stop middlemanager historical broker
4. Stop coordinator/router: docker compose stop coordinator router
5. Pull new images: docker compose pull
6. Start coordinator first: docker compose up -d coordinator
7. Wait for coordinator healthy in web console
8. Bring up remaining services: docker compose up -d
9. Verify segment replication and task queue

## Gotchas

- Memory hungry — default compose needs ~4GB+; tune DRUID_XMX per service
- ZooKeeper dependency — requires ZK 3.5+; production needs ZK ensemble (3+ nodes)
- environment file — config uses env_file: environment (not .env); create this file before docker compose up
- Deep storage for prod — local deep storage only works single-node; use S3/GCS/Azure for multi-node
- Metadata DB — default Derby is dev-only/ephemeral; switch to PostgreSQL or MySQL for production
- Port range — MiddleManager uses 8100-8105 for task workers; ensure firewall allows these
- First ingest is slow — tasks spin up JVMs; expect 30-60s task startup
- Resource-intensive — each Druid node is a separate JVM; plan for 8GB+ RAM for minimal cluster

## Links

- Upstream README: https://github.com/apache/druid/blob/master/README.md
- Docker quickstart: https://druid.apache.org/docs/latest/tutorials/docker.html
- Configuration reference: https://druid.apache.org/docs/latest/configuration/
- Kubernetes operator: https://github.com/apache/druid-operator
