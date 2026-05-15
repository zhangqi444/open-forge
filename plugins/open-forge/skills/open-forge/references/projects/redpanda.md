---
name: redpanda
description: Redpanda recipe for open-forge. Covers Docker, Docker Compose, and Linux binary install. Kafka-compatible streaming data platform written in C++; no ZooKeeper or JVM required; 10x lower latency than Kafka. Sourced from https://github.com/redpanda-data/redpanda and https://docs.redpanda.com/current/get-started/quick-start/.
---

# Redpanda

Apache Kafka®-compatible streaming data platform written in C++. Eliminates ZooKeeper and JVM for simpler operations and dramatically lower latency. Drop-in replacement for Kafka — existing Kafka clients, connectors, and tooling work unchanged. Upstream: https://github.com/redpanda-data/redpanda. Docs: https://docs.redpanda.com/. BSL 1.1 (free for self-hosted use).

Redpanda includes a built-in Schema Registry, HTTP Proxy (Pandaproxy), and Redpanda Console (web UI). Managed cloud offering (Redpanda Cloud) also available.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose | https://docs.redpanda.com/current/get-started/quick-start/ | Dev and small production |
| Linux binary (rpk) | https://docs.redpanda.com/current/get-started/rpk-install/ | Production bare-metal; single binary |
| Kubernetes (Helm/Operator) | https://docs.redpanda.com/current/deploy/deployment-option/self-hosted/kubernetes/ | Production cluster |
| Redpanda Cloud | https://redpanda.com/redpanda-cloud | Managed SaaS; out of scope for open-forge |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Docker Compose, Linux binary, or Kubernetes?" | Drives method |
| cluster | "Single broker or multi-broker cluster?" | Multi-broker for HA |
| auth | "Enable SASL authentication?" | Default: no auth |
| schema | "Enable Schema Registry?" | Included; port 8081 |
| console | "Include Redpanda Console web UI?" | Included in Compose quickstart |

## Docker Compose quickstart

```yaml
version: "3.8"
services:
  redpanda:
    image: docker.redpanda.com/redpandadata/redpanda:v26.1.8
    command:
      - redpanda
      - start
      - --kafka-addr internal://0.0.0.0:9092,external://0.0.0.0:19092
      - --advertise-kafka-addr internal://redpanda:9092,external://localhost:19092
      - --pandaproxy-addr internal://0.0.0.0:8082,external://0.0.0.0:18082
      - --advertise-pandaproxy-addr internal://redpanda:8082,external://localhost:18082
      - --schema-registry-addr internal://0.0.0.0:8081,external://0.0.0.0:18081
      - --rpc-addr redpanda:33145
      - --advertise-rpc-addr redpanda:33145
      - --smp 1
      - --memory 1G
      - --mode dev-container
      - --overprovisioned
      - --default-log-level=info
    ports:
      - "18081:18081"   # Schema Registry (external)
      - "18082:18082"   # HTTP Proxy (external)
      - "19092:19092"   # Kafka API (external)
      - "9644:9644"     # Admin API
    volumes:
      - redpanda-data:/var/lib/redpanda/data

  console:
    image: docker.redpanda.com/redpandadata/console:v3.7.2
    environment:
      CONFIG_FILEPATH: /tmp/config.yml
    entrypoint: /bin/sh
    command: -c 'printf "kafka:\n  brokers:\n    - redpanda:9092\n" > /tmp/config.yml && /app/console'
    ports:
      - "8080:8080"    # Redpanda Console web UI
    depends_on:
      - redpanda

volumes:
  redpanda-data:
```

Access Console at http://localhost:8080.

## Key ports

| Port | Purpose |
|---|---|
| 19092 | Kafka API (external; use this from clients) |
| 9092 | Kafka API (internal; within Docker network) |
| 18081 | Schema Registry |
| 18082 | HTTP Proxy (Pandaproxy) |
| 9644 | Admin API |
| 8080 | Redpanda Console (web UI) |

## rpk CLI (topic management)

```sh
# Create topic
rpk topic create my-topic --brokers localhost:19092

# Produce
echo "hello redpanda" | rpk topic produce my-topic --brokers localhost:19092

# Consume
rpk topic consume my-topic --brokers localhost:19092

# List topics
rpk topic list --brokers localhost:19092
```

## Linux binary install

```sh
# Debian/Ubuntu
curl -1sLf 'https://dl.redpanda.com/nzc4ZYQK3WRGd9sy/redpanda/cfg/setup/bash.deb.sh' | sudo -E bash
sudo apt-get install redpanda

# Start
sudo systemctl start redpanda
```

## Upgrade procedure

```sh
# Docker: update image tag in Compose file
docker compose pull && docker compose up -d

# Linux binary (Debian/Ubuntu)
sudo apt-get update && sudo apt-get install --only-upgrade redpanda
```

For cluster upgrades, upgrade one broker at a time (rolling upgrade); check docs for version-specific migration notes.

## Gotchas

- **--mode dev-container** — this flag relaxes resource limits for local dev; remove for production (use `--mode production` or omit).
- **--overprovisioned** — disables CPU affinity and IO scheduling optimizations for containerized dev; remove for production bare-metal.
- **No ZooKeeper** — Redpanda uses its own Raft-based consensus (Raft metadata); ZooKeeper connection strings in legacy configs are ignored/unsupported.
- **Kafka client compatibility** — fully compatible with Kafka clients (librdkafka, kafka-python, confluent-kafka, etc.); just point broker address to Redpanda.
- **BSL 1.1 license** — free for self-hosted use; production use in a managed/cloud service offering requires a commercial license.
- **Schema Registry** — included and Confluent Schema Registry API-compatible; no separate service needed.
- **--smp flag** — controls number of CPU cores Redpanda uses; defaults to all cores; set explicitly in containers to match CPU limits.

## Links

- GitHub: https://github.com/redpanda-data/redpanda
- Quickstart: https://docs.redpanda.com/current/get-started/quick-start/
- rpk CLI reference: https://docs.redpanda.com/current/reference/rpk/
- Docker image: https://hub.docker.com/r/redpandadata/redpanda
- Kafka compatibility: https://docs.redpanda.com/current/develop/kafka-clients/
