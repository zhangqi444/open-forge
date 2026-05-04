---
name: clickhouse
description: ClickHouse recipe for open-forge. Covers Docker, Docker Compose, and Linux binary install for the open-source column-oriented OLAP database. Optimized for real-time analytical queries on large datasets. Sourced from https://github.com/ClickHouse/ClickHouse and https://clickhouse.com/docs/getting-started/quick-start.
---

# ClickHouse

Open-source column-oriented database management system (DBMS) designed for real-time OLAP (Online Analytical Processing). Generates analytical reports over billions of rows in milliseconds. Used for observability, business intelligence, time-series, and log analytics workloads. Upstream: https://github.com/ClickHouse/ClickHouse. Docs: https://clickhouse.com/docs/.

ClickHouse supports SQL with extensions for analytical functions, materialized views, TTL-based data expiry, and sharding/replication via ClickHouse Keeper (or ZooKeeper).

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker (single node) | https://clickhouse.com/docs/install#docker | Dev / small deployments |
| Linux binary (curl installer) | https://clickhouse.com/docs/install#quick-install | Production single-node on Linux |
| Docker Compose (single node) | https://clickhouse.com/docs/install#docker | Reproducible dev environment |
| Kubernetes (Helm / Operator) | https://clickhouse.com/docs/install#available-installation-options | Production cluster |
| ClickHouse Cloud | https://clickhouse.cloud | Managed; out of scope for open-forge |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Single node or cluster (sharding + replication)?" | Cluster requires ClickHouse Keeper or ZooKeeper |
| auth | "Set a default password for the default user?" | Default user has no password |
| storage | "Data directory path?" | Default: /var/lib/clickhouse |
| port | "Expose HTTP API (8123) and native TCP (9000) externally?" | Consider firewall rules |
| tls | "TLS for HTTP interface?" | Recommended for production |

## Docker quickstart

```sh
docker run -d \
  --name clickhouse \
  -p 8123:8123 \
  -p 9000:9000 \
  -v clickhouse-data:/var/lib/clickhouse \
  -v clickhouse-logs:/var/log/clickhouse-server \
  clickhouse/clickhouse-server:latest
```

Connect via HTTP:
```sh
curl http://localhost:8123/?query=SELECT+version()
```

Connect via native client:
```sh
docker exec -it clickhouse clickhouse-client
```

## Docker Compose

```yaml
version: "3.8"
services:
  clickhouse:
    image: clickhouse/clickhouse-server:latest
    ports:
      - "8123:8123"   # HTTP interface
      - "9000:9000"   # Native TCP
    environment:
      CLICKHOUSE_DB: default
      CLICKHOUSE_USER: default
      CLICKHOUSE_PASSWORD: changeme
      CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT: 1
    volumes:
      - clickhouse-data:/var/lib/clickhouse
      - clickhouse-logs:/var/log/clickhouse-server
    ulimits:
      nofile:
        soft: 262144
        hard: 262144

volumes:
  clickhouse-data:
  clickhouse-logs:
```

## Linux binary install

```sh
curl https://clickhouse.com/ | sh
sudo ./clickhouse install

# Start service
sudo systemctl start clickhouse-server

# Connect
clickhouse-client
```

## Key ports

| Port | Protocol | Purpose |
|---|---|---|
| 8123 | HTTP | REST-like query API; compatible with many BI tools |
| 9000 | TCP | Native ClickHouse protocol; used by clickhouse-client |
| 9440 | TCP+TLS | Native protocol with TLS |
| 9009 | TCP | Inter-server replication |

## Key configuration

Config files live in /etc/clickhouse-server/ (binary install) or are embedded in the image (Docker).

Key settings in config.xml / config.d/*.xml:
- `<listen_host>` — bind address (0.0.0.0 to accept external connections)
- `<path>` — data directory
- `<tmp_path>` — temp files for large queries
- `<max_memory_usage>` — per-query memory limit
- `<max_concurrent_queries>` — concurrency limit

Users and access control: /etc/clickhouse-server/users.xml or SQL-based access management (set CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1).

## Upgrade procedure

```sh
# Docker: update image tag and recreate
docker compose pull && docker compose up -d

# Binary: re-run installer (preserves data directory)
curl https://clickhouse.com/ | sh
sudo ./clickhouse install
sudo systemctl restart clickhouse-server
```

## Gotchas

- **Default user has no password** — set CLICKHOUSE_PASSWORD or configure users.xml before exposing to any network.
- **ulimits** — ClickHouse needs high file descriptor limits; set `nofile: 262144` in Docker or `ulimit -n 262144` on the host.
- **Column-oriented means wide tables are efficient, tall tables are cheap** — avoid SELECT *; always specify column lists.
- **Materialized views are insert-time only** — they do not backfill historical data; insert data after creating the view.
- **Replication requires ClickHouse Keeper** — built-in Keeper (recommended) or external ZooKeeper; single-node installs don't need it.
- **MergeTree engine family** — most production tables use ReplicatedMergeTree (replicated) or MergeTree (single-node); choose at CREATE TABLE time, not later.
- **TTL for log retention** — use `TTL timestamp + INTERVAL 30 DAY DELETE` in the CREATE TABLE statement to auto-expire old data.
- **HTTP vs native protocol** — HTTP (port 8123) is simpler and firewall-friendly; native TCP (port 9000) is faster for bulk inserts and clickhouse-client.

## Links

- GitHub: https://github.com/ClickHouse/ClickHouse
- Quick start: https://clickhouse.com/docs/getting-started/quick-start
- Install options: https://clickhouse.com/docs/install
- Docker image: https://hub.docker.com/r/clickhouse/clickhouse-server
- SQL reference: https://clickhouse.com/docs/sql-reference
