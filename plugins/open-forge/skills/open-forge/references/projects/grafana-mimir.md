---
name: grafana-mimir
description: Grafana Mimir recipe for open-forge. Open-source horizontally scalable, highly available, multi-tenant, long-term storage for Prometheus metrics backed by object storage.
---

# Grafana Mimir

Open-source, horizontally scalable, highly available Prometheus-compatible metrics backend. Stores metrics long-term in object storage (S3, GCS, Azure Blob, MinIO). Supports up to 1 billion active time series and multi-tenancy. AGPL-3.0 licensed. Upstream: <https://github.com/grafana/mimir>. Docs: <https://grafana.com/docs/mimir/latest/>.

Mimir is the spiritual successor to Cortex; it is also the more scalable alternative to Thanos for teams wanting a single unified binary rather than composable sidecars.

## Compatible install methods

| Method | When to use |
|---|---|
| Monolithic Docker (single binary) | Dev / small teams; easiest start |
| Docker Compose (microservices) | Medium scale; separates components |
| Helm (Kubernetes) | Production; full horizontal scaling |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Monolithic or microservices mode?" | Monolithic = single process; easier to start |
| preflight | "Object storage provider?" | S3, GCS, Azure Blob, MinIO |
| preflight | "S3 bucket name / endpoint / credentials?" | Required for block storage |
| preflight | "Multi-tenant? Or single tenant?" | Single-tenant: use `X-Scope-OrgID: anonymous` header |

## Monolithic Docker Compose

```yaml
version: "3.9"
services:
  mimir:
    image: grafana/mimir:latest
    command: ["-config.file=/etc/mimir/config.yml"]
    ports:
      - "9009:9009"   # HTTP (query, push, UI)
    volumes:
      - ./mimir-config.yml:/etc/mimir/config.yml
      - mimir-data:/data

volumes:
  mimir-data:
```

### Minimal mimir-config.yml (monolithic, local disk)

```yaml
target: all

common:
  storage:
    backend: filesystem
    filesystem:
      dir: /data/blocks

blocks_storage:
  tsdb:
    dir: /data/tsdb

ruler_storage:
  backend: filesystem
  filesystem:
    dir: /data/rules

alertmanager_storage:
  backend: filesystem
  filesystem:
    dir: /data/alertmanager

memberlist:
  join_members: []
```

For object storage, replace `filesystem` backend with S3/GCS/Azure config per docs: <https://grafana.com/docs/mimir/latest/operators-guide/configure/reference-configuration-parameters/#s3>

## Prometheus remote_write to Mimir

```yaml
# prometheus.yml
remote_write:
  - url: http://mimir:9009/api/v1/push
    headers:
      X-Scope-OrgID: "anonymous"   # required even for single-tenant
```

## Software-layer concerns

- Port: `9009` (HTTP: query frontend, push endpoint, admin UI at `/`)
- `X-Scope-OrgID` header is **required** on all requests — use `anonymous` for single-tenant
- Grafana datasource: Prometheus type, URL `http://mimir:9009/prometheus`, add custom header `X-Scope-OrgID: anonymous`
- License: AGPL-3.0 — enterprise features (SSO, enhanced RBAC) available in Grafana Cloud
- Migrating from Thanos/Cortex: see <https://grafana.com/docs/mimir/latest/set-up/migrate/>

## Upgrade procedure

1. Pull new image: `docker compose pull mimir`
2. Restart: `docker compose up -d mimir`
3. Check Mimir changelog for schema migrations; monolithic mode handles them automatically

## Gotchas

- `X-Scope-OrgID` is easy to forget — Grafana datasource must send it or queries return 400
- Filesystem backend is fine for dev; use object storage (MinIO/S3) for production durability
- Monolithic mode runs all components in one process — fine up to ~10M active series; beyond that, switch to microservices mode
- AGPL-3.0 license means SaaS offerings using Mimir must open-source modifications

## Links

- GitHub: <https://github.com/grafana/mimir>
- Docs: <https://grafana.com/docs/mimir/latest/>
- Get started: <https://grafana.com/docs/mimir/latest/get-started/>
- Docker Hub: <https://hub.docker.com/r/grafana/mimir>
