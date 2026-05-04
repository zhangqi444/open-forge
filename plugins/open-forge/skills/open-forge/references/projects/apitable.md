---
name: apitable
description: Recipe for APITable — open-source, real-time collaborative spreadsheet-database platform (Airtable alternative).
---

# APITable

Open-source, API-oriented collaborative spreadsheet-database platform. Airtable alternative with real-time collaboration, 10M+ rows per sheet, automatic REST API, formula fields, views (grid, kanban, gallery, calendar, Gantt), forms, automation, and embedding. Backend: Java/Spring + Node.js. Frontend: React. Database: MySQL + Redis + MinIO. Upstream: <https://github.com/apitable/apitable>. Docs: <https://help.aitable.ai>. License: AGPL-3.0. ~14K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Install script (Docker Compose) | <https://github.com/apitable/apitable#installation> | ✅ | Recommended production. Multi-container stack via `curl ... \| bash`. |
| All-in-one Docker image | <https://github.com/apitable/apitable#installation> | ✅ | Demo/testing only. Not for production. amd64 only. |
| DigitalOcean App Platform | <https://cloud.digitalocean.com/apps/new?repo=https://github.com/apitable/apitable/tree/develop> | Community | One-click cloud deploy. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | "Domain or IP for APITable?" | hostname / IP | All methods |
| infra | "MySQL root password?" | Sensitive string | Compose install |
| infra | "MinIO access key + secret?" | Sensitive strings | Compose install |
| software | "Admin email address?" | Email | First-run setup |

## Software-layer concerns

### Install script (recommended)

Requires Docker + Docker Compose v2, 4 CPUs / 8 GB RAM minimum.

```bash
curl https://apitable.github.io/install.sh | bash
```

This downloads a `docker-compose.yml` into the current directory and starts the full stack. Visit `http://localhost:80` after all services start (may take several minutes on first run).

### All-in-one image (demo/test only)

```bash
sudo docker run -d \
  -v ${PWD}/.data:/apitable \
  -p 80:80 \
  --name apitable \
  apitable/all-in-one:latest
```

⚠️ amd64 only. Poor performance on arm64/Apple Silicon. Not suitable for production.

### Service stack (Compose)

The install script deploys:

| Service | Purpose |
|---|---|
| `web-server` | React frontend (Nginx) |
| `backend-server` | Java/Spring REST API |
| `room-server` | Node.js real-time collaboration (WebSocket) |
| `databus-server` | Data access layer |
| `mysql` | Primary database |
| `redis` | Cache + pub/sub |
| `minio` | Object storage (attachments) |
| `rabbitmq` | Message queue |
| `init-db` | One-shot DB migration job |

### Data directories

All services persist to named Docker volumes. With the install script, look for `docker-compose.yml` to find volume definitions.

### Key ports

| Port | Service |
|---|---|
| 80 | Frontend (Nginx) |
| 3000 | backend-server (internal) |
| 3001 | room-server (internal) |
| 9000 | MinIO API (internal) |

## Upgrade procedure

```bash
# Pull latest docker-compose.yml changes
curl https://apitable.github.io/install.sh | bash
# Or manually:
docker compose pull
docker compose up -d
```

The `init-db` container runs schema migrations automatically on startup.

## Gotchas

- **High resource requirements**: 4 CPU / 8 GB RAM is the practical minimum. 8+ CPU / 16 GB RAM recommended for teams.
- **amd64 only (all-in-one)**: The all-in-one image has no arm64 support; use the Compose install on ARM hosts.
- **Slow first start**: All services initialize on first boot — wait 3–5 minutes before visiting the UI.
- **init-db must complete**: If `init-db` exits with an error, the backend won't start. Check `docker compose logs init-db` if the UI doesn't load.
- **MinIO configuration**: Attachments are stored in MinIO. Back up MinIO volumes alongside MySQL for complete data recovery.
- **No built-in reverse proxy/TLS**: Use Nginx, Caddy, or Traefik in front for HTTPS in production.
- **Community project status**: APITable's commercial entity (AITable) is separate from the OSS project; check GitHub activity before relying on it for critical workloads.

## Links

- GitHub: <https://github.com/apitable/apitable>
- Help Center: <https://help.aitable.ai>
- Developer Center: <https://developers.aitable.ai>
- Discord: <https://discord.gg/TwNb9nfdBU>
- Docker Hub: <https://hub.docker.com/r/apitable/all-in-one>
