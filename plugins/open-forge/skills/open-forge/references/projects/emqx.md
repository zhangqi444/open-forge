---
name: emqx-project
description: EMQX recipe for open-forge. Covers Docker single-node, Docker Compose, and Kubernetes (EMQX Operator) install as documented at https://docs.emqx.com/en/emqx/latest/deploy/install.html.
---

# EMQX

World's most scalable open source MQTT platform. Supports MQTT 5.0, 3.1.1, 3.1, MQTT-SN, CoAP, LwM2M, and MQTT over QUIC. Designed for IoT, IIoT, connected vehicles, and AI data pipelines — handles millions of concurrent connections and millions of messages/second. Built on Erlang/OTP. Upstream: <https://github.com/emqx/emqx>. Official site: <https://www.emqx.io/>. Docs: <https://docs.emqx.com/en/emqx/latest/>.

> **License note:** Starting with v5.9.0, EMQX unified its OSS and Enterprise editions into a single release under the Business Source License (BSL) 1.1. Older v5.x OSS releases used Apache 2.0. BSL permits self-hosting and production use; commercial redistribution requires a license.

## Compatible install methods

| Method | Upstream reference | When to use |
|---|---|---|
| Docker single node | <https://docs.emqx.com/en/emqx/latest/deploy/install-docker.html> | Quickest start; dev and small production |
| Docker Compose | <https://docs.emqx.com/en/emqx/latest/deploy/install-docker.html> | Multi-service setups with volume persistence |
| Kubernetes (EMQX Operator) | <https://docs.emqx.com/en/emqx-operator/latest/getting-started/getting-started.html> | Production clustering on Kubernetes |
| Package (RPM/DEB) | <https://docs.emqx.com/en/emqx/latest/deploy/install.html> | Bare-metal or VM installs without Docker |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which EMQX version to deploy?" | Tag e.g. `5.9` or `latest` | Use `emqx/emqx-enterprise` image |
| security | "New admin password?" | String | Default `public` must be changed immediately |
| ports | "Which ports to expose?" | Comma-separated | See port table below; at minimum expose 1883 + 18083 |
| persistence | "Where to persist EMQX data?" | Host path | Mounted at `/opt/emqx/data` |
| clustering (optional) | "Number of nodes in cluster?" | Integer | Single-node for dev; multi-node uses EMQX Operator |

## Docker quick-start (from upstream README)

```bash
docker run -d --name emqx \
  -p 1883:1883 \
  -p 8083:8083 \
  -p 8084:8084 \
  -p 8883:8883 \
  -p 18083:18083 \
  emqx/emqx-enterprise:latest
```

Access the Dashboard at `http://localhost:18083`. Default credentials: `admin` / `public` — **change immediately**.

For persistence, add: `-v $(pwd)/emqx-data:/opt/emqx/data`

## Software-layer concerns

| Concern | Detail |
|---|---|
| Ports | 1883 = MQTT (TCP), 8083 = MQTT over WebSocket, 8084 = MQTT over WebSocket/TLS, 8883 = MQTT/TLS, 18083 = Dashboard (HTTP) |
| Dashboard | `http://<host>:18083` — default `admin`/`public`. **Must change password on first login.** |
| Data dir | `/opt/emqx/data` — persists sessions, retained messages, ACL rules, built-in database. Bind-mount this volume. |
| Log dir | `/opt/emqx/log` — optional to persist for debugging |
| Config | Environment variables (e.g. `EMQX_DASHBOARD__DEFAULT_PASSWORD`) or `/opt/emqx/etc/emqx.conf` mount |
| TLS | Mount certs and configure via `EMQX_LISTENERS__SSL__DEFAULT__SSL_OPTIONS__CERTFILE` env vars, or via Dashboard |
| Clustering | Masterless cluster. For Docker, set `EMQX_NODE__NAME` and `EMQX_CLUSTER__DISCOVERY_STRATEGY`. Production clustering: use EMQX Operator on Kubernetes. |
| Rule Engine | Built-in SQL-based rule engine for data processing/routing to 50+ integrations (Kafka, PostgreSQL, InfluxDB, etc.) |
| License | BSL 1.1 (v5.9+): permits self-hosting and production use; prohibits commercial redistribution without license |

## Upgrade procedure

Per <https://docs.emqx.com/en/emqx/latest/deploy/upgrade-cluster.html>:

**Single node:**
1. Back up data: `docker cp emqx:/opt/emqx/data ./emqx-backup`
2. Pull new image: `docker pull emqx/emqx-enterprise:<new-version>`
3. Stop and remove old container, start new one with same volume mounts and ports.

**Cluster (rolling upgrade):**
1. Upgrade nodes one at a time — EMQX supports rolling upgrades within a minor version.
2. For major version upgrades, consult the upstream migration guide first.

## Gotchas

- **Default password**: `admin`/`public` is the dashboard default — change it before exposing any port publicly.
- **BSL license**: v5.9+ is BSL, not Apache 2.0. For commercial redistribution use cases, review the license terms.
- **Port conflicts**: 1883 clashes with any existing MQTT broker on the host. Check before running.
- **Data volume required**: without `-v` mounting `/opt/emqx/data`, sessions and retained messages are lost on container restart.
- **RAM usage**: EMQX is designed for scale; a minimal single-node instance uses ~200–400 MB RAM at idle. Tune `node.process_limit` and `node.max_ports` for small VMs.

## Links

- Upstream README: <https://github.com/emqx/emqx>
- Install docs (Docker): <https://docs.emqx.com/en/emqx/latest/deploy/install-docker.html>
- EMQX Operator (Kubernetes): <https://docs.emqx.com/en/emqx-operator/latest/getting-started/getting-started.html>
- Docker Hub: <https://hub.docker.com/r/emqx/emqx-enterprise/tags>
- Dashboard docs: <https://docs.emqx.com/en/emqx/latest/dashboard/introduction.html>
