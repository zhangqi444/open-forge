---
name: nats
description: Recipe for NATS Server — open-source, high-performance messaging system for cloud-native distributed systems. CNCF project.
---

# NATS Server

Simple, secure, and high-performance messaging system for cloud-native distributed systems. Supports pub/sub, request/reply, and queue groups. JetStream (built-in) adds persistence, at-least-once delivery, key/value store, and object store. Single binary, no external dependencies. CNCF project. 40+ client language implementations. Upstream: <https://github.com/nats-io/nats-server>. Docs: <https://docs.nats.io>. License: Apache-2.0. ~16K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/_/nats> | Yes | Recommended containerized deployment |
| Docker Compose | Standard Compose config | Yes | Multi-service stacks |
| Linux binary | <https://github.com/nats-io/nats-server/releases> | Yes | Bare-metal; single static binary |
| Helm chart | <https://artifacthub.io/packages/helm/nats/nats> | Yes | Kubernetes deployments |
| Homebrew | `brew install nats-server` | Yes | macOS |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Port for NATS client connections? | Port (default 4222) | All |
| infra | Port for cluster routing (multi-node)? | Port (default 6222) | Clustering only |
| infra | Port for monitoring HTTP? | Port (default 8222) | Optional; enables /healthz, /varz, /connz |
| software | Enable JetStream? | Boolean | Optional; adds persistence |
| software | JetStream storage dir? | Absolute path | Required if JetStream enabled |
| software | Enable TLS? | Boolean | Recommended for production |
| software | Username/password or NKey auth? | Credentials type | Optional; choose auth method |

## Software-layer concerns

### Docker run (simplest, no persistence)

```bash
docker run -d \
  --name nats \
  -p 4222:4222 \
  -p 8222:8222 \
  nats:latest
```

- Port 4222: client connections
- Port 8222: HTTP monitoring (http://localhost:8222)

### Docker Compose with JetStream

```yaml
services:
  nats:
    image: nats:latest
    container_name: nats
    restart: unless-stopped
    ports:
      - "4222:4222"   # clients
      - "8222:8222"   # monitoring
    volumes:
      - ./nats-config.conf:/etc/nats/nats.conf:ro
      - nats-data:/data/jetstream
    command: ["-c", "/etc/nats/nats.conf"]

volumes:
  nats-data:
```

### nats-config.conf

```conf
# Basic configuration with JetStream and auth
port: 4222
http: 8222

# JetStream
jetstream {
  store_dir: /data/jetstream
  max_mem: 1G
  max_file: 10G
}

# Simple username/password auth
authorization {
  user: natsuser
  password: "changeMe123!"
  timeout: 3
}

# Cluster (uncomment for multi-node)
# cluster {
#   name: my-cluster
#   port: 6222
#   routes: [
#     nats-route://nats-node2:6222
#     nats-route://nats-node3:6222
#   ]
# }
```

### JetStream features

| Feature | Description |
|---|---|
| Streams | Persistent message storage with configurable retention |
| Consumers | Push or pull subscription with ack tracking |
| Key/Value | Bucket-based KV store built on JetStream |
| Object Store | Blob storage built on JetStream |

### NATS CLI (`nats` tool)

```bash
# Install
brew install nats-io/nats-tools/nats   # macOS
# or download from https://github.com/nats-io/natscli/releases

# Publish
nats pub my.subject "hello world"

# Subscribe
nats sub my.subject

# JetStream stream create
nats stream create ORDERS --subjects "orders.>" --storage file

# Monitor
nats server info
nats server ping
```

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

JetStream data is backwards-compatible across minor versions. Review release notes for major version upgrades: <https://github.com/nats-io/nats-server/releases>

## Gotchas

- JetStream disabled by default: core NATS (pub/sub) has no persistence. Enable JetStream explicitly if you need at-least-once delivery or replay.
- At-most-once by default: core NATS does not acknowledge messages — if no subscriber is listening when a message is published, it is lost. Use JetStream for durable messaging.
- Auth disabled by default: NATS starts with no authentication in dev mode. Always configure auth for internet-exposed deployments.
- Port 8222 monitoring: exposes connection stats and server info. Don't expose it publicly without auth.
- Clustering: multi-node clusters use a gossip-based route mesh. All nodes must be able to reach each other on port 6222.
- NATS vs JetStream: treat them as distinct mental models — core NATS for fire-and-forget messaging, JetStream for durable queues, event streams, and KV.

## Links

- GitHub: <https://github.com/nats-io/nats-server>
- Docs: <https://docs.nats.io>
- Docker Hub: <https://hub.docker.com/_/nats>
- NATS CLI: <https://github.com/nats-io/natscli>
- JetStream docs: <https://docs.nats.io/nats-concepts/jetstream>
- Helm chart: <https://artifacthub.io/packages/helm/nats/nats>
