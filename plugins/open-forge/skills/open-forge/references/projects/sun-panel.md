---
name: sun-panel
description: Sun-Panel recipe for open-forge. Self-hosted NAS/server navigation panel and browser homepage with icon-based app launcher, Docker support, and multi-account isolation. Upstream: https://github.com/hslr-s/sun-panel
---

# Sun-Panel

A server/NAS navigation panel, homepage, and browser start page with a clean icon-based interface, multi-account isolation, and zero external database dependency. Upstream: <https://github.com/hslr-s/sun-panel>. Documentation: <https://sun-panel-doc.enianteam.com>.

> **Note:** As of 2025, the project entered partial closed-source for PRO features. The last fully open-source release is `v1.3.0`. The Docker image `hslr/sun-panel:latest` continues to receive updates but some advanced features require a PRO license. Core navigation/homepage functionality remains free.

Sun-Panel is a Go-based single-binary container with an embedded SQLite database — no external Postgres/MySQL required. Configuration and uploads persist via bind mounts.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host / NAS | Docker Compose | Recommended — single service, simple bind mounts. |
| Any Linux host / NAS | `docker run` | Works; use `docker-compose.yml` from upstream as reference. |
| Synology NAS | Docker UI / Container Manager | Popular deployment target; arm64 image available. |
| ARM (Raspberry Pi, NAS) | Docker | Multi-arch image supports `linux/amd64` and `linux/arm64`. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which port should Sun-Panel listen on?" | Integer | Default `3002`. Must be free on the host. |
| preflight | "Where should Sun-Panel store its config and database?" | Directory path | E.g. `/opt/sun-panel`. Will hold `conf/`, `uploads/`, `database/` subdirs. |
| auth | "Set a strong admin password after first login" | Reminder | First-run wizard creates the admin account; no env var for initial password. |

## Software-layer concerns

### Config and data paths

Inside the container, Sun-Panel uses:

| Purpose | Container path | Recommended host bind |
|---|---|---|
| App config (settings) | `/app/conf` | `<data-dir>/conf` |
| Uploaded icons / images | `/app/uploads` | `<data-dir>/uploads` |
| SQLite database | `/app/database` | `<data-dir>/database` |

All three directories must be writable by the container process.

### Environment variables

Sun-Panel does not require environment variables for basic operation — all settings are configured via the web UI. The container exposes port `3002` by default.

### docker-compose.yml (from upstream)

```yaml
version: "3.2"

services:
  sun-panel:
    image: hslr/sun-panel:latest
    container_name: sun-panel
    volumes:
      - ./conf:/app/conf
      - ./uploads:/app/uploads
      - ./database:/app/database
    ports:
      - "3002:3002"
    restart: always
```

Source: <https://github.com/hslr-s/sun-panel/blob/master/docker-compose.yml>

### First-run setup

Navigate to `http://<host>:3002` — the setup wizard prompts to create the admin account on first access. Set a strong password immediately; Sun-Panel has no rate-limiting on the login form by default.

## Upgrade procedure

```bash
# Pull new image
docker compose pull

# Recreate container (config and database persist via bind mounts)
docker compose up -d --force-recreate
```

Sun-Panel handles database migrations automatically on startup. Check `docker logs sun-panel` after the update to confirm a clean start.

## Gotchas

- **PRO features require a license** — as of v1.3.0+, some features require a paid PRO license from <https://pro.sun-panel.top>. The navigation/homepage core is free.
- **No HTTPS built-in** — Sun-Panel serves plain HTTP. For production, place a reverse proxy (Nginx, Caddy, Traefik) in front to terminate TLS.
- **ARM support** — `hslr/sun-panel:latest` is multi-arch (`linux/amd64`, `linux/arm64`). Verify release notes when pinning a specific version tag.
- **No external DB required** — embedded SQLite; do not attempt to point it at an external database.
- **Data dir permissions** — create bind-mount directories before starting (`mkdir -p conf uploads database`) to avoid root-owned creation.
- **Multiple accounts** — account isolation (each user sees their own panel) is configured from the admin UI, not via environment variables.

## Upstream docs

- GitHub: <https://github.com/hslr-s/sun-panel>
- English documentation: <https://sun-panel-doc.enianteam.com>
- Chinese documentation: <https://sun-panel-doc.enianteam.com/zh_cn>
- Docker Hub: <https://hub.docker.com/r/hslr/sun-panel>
- Deployment guide: <https://sun-panel-doc.enianteam.com/usage/quick_deploy.html>
