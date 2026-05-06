# RudderStack

> Collect, unify, transform, and store your customer data, and route it to a wide range of common, popular marketing, sales, and product tools (alternative to Segment).

**URL:** https://rudderstack.com/  
**License:** Elastic-2.0  
**Source:** https://github.com/rudderlabs/rudder-server  
**Language:** Go, React.js

---

## What it is

RudderStack is an open-source Customer Data Platform (CDP) that provides data pipelines to collect events from every application, website, and SaaS platform, then route that data to warehouses and business tools. It is fully Segment API-compatible, meaning existing Segment integrations can be pointed at RudderStack with minimal code changes. The backend is written in Go with PostgreSQL as its only hard dependency; over 90 destination integrations are supported via a companion transformer service.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended for quick self-hosted start |
| Any Linux | Kubernetes (Helm) | Recommended for production deployments |
| Any Linux | Bare metal | Go binary + PostgreSQL required |

---

## Inputs to Collect

### Phase: Install
| Variable | Description | Example |
|----------|-------------|---------|
| `DOMAIN` | Your domain or IP for the backend API | `rudder.example.com` |
| `PORT` | Backend API port | `8080` |
| `JOBS_DB_HOST` | PostgreSQL host | `db` |
| `JOBS_DB_PORT` | PostgreSQL port | `5432` |
| `JOBS_DB_USER` | PostgreSQL user | `rudder` |
| `JOBS_DB_PASSWORD` | PostgreSQL password | `changeme` |
| `JOBS_DB_DB_NAME` | PostgreSQL database name | `jobsdb` |
| `WORKSPACE_TOKEN` | RudderStack workspace token (from control plane) | `<token>` |

---

## Software-Layer Concerns

- **Config:** Environment variables via `build/docker.env`; workspace config can be mounted at `/etc/rudderstack/workspaceConfig.json`
- **Data dir:** PostgreSQL stores all job/event state
- **Env vars:** `JOBS_DB_HOST`, `JOBS_DB_PORT`, `JOBS_DB_USER`, `JOBS_DB_PASSWORD`, `JOBS_DB_DB_NAME`, `WORKSPACE_TOKEN`, `CONFIG_BACKEND_URL`
- **Transformer service:** Companion `rudder-transformer` (port 9090) is required for most destination integrations

---

## Upgrade Procedure

1. Pull new images: `docker pull rudderlabs/rudder-server:latest && docker pull rudderstack/rudder-transformer:latest`
2. Stop containers: `docker compose down`
3. Restart: `docker compose up -d`
4. Check release notes at https://github.com/rudderlabs/rudder-server/blob/master/CHANGELOG.md for migration steps

---

## Gotchas

- In production, Helm charts are strongly recommended over Docker Compose — Docker images receive bug-fixes more frequently than the Compose file
- The `rudder-transformer` service is a hard dependency; many destinations will fail without it
- `WORKSPACE_TOKEN` is obtained from the RudderStack cloud control plane (a free-tier cloud account manages workspace config even in self-hosted mode)
- Elastic License 2.0 prohibits offering RudderStack as a managed service to third parties
- Optional `minio` (for storage) and `etcd` (for multi-tenant mode) are in Compose but disabled by default via Docker profiles

---

## References

- [Upstream README](https://github.com/rudderlabs/rudder-server#readme)
- [Official docs](https://www.rudderstack.com/docs/)
- [Docker setup guide](https://www.rudderstack.com/docs/rudderstack-open-source/installing-and-setting-up-rudderstack/docker/)
