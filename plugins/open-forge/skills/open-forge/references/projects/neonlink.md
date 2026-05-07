---
name: neonlink
description: NeonLink recipe for open-forge. Lightweight self-hosted bookmark service with a unique neon design. Tags, search, auto-fetch icons/titles/descriptions, customizable backgrounds. Docker + SQLite. Source: https://github.com/AlexSciFier/neonlink
---

# NeonLink

Simple, lightweight, self-hosted bookmark manager with a distinctive neon/dark aesthetic. Auto-fetches page icons, titles, and descriptions on save. Supports tags, search, and customizable background images. Built with React (frontend) and Fastify (backend), using SQLite for storage. Single Docker container. Low resource usage — suitable for Raspberry Pi. MIT licensed.

Upstream: <https://github.com/AlexSciFier/neonlink>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (single container) | Recommended — official image on DockerHub |
| Any | Docker Compose | Compose file included in repo |
| Any (ARM) | Docker (arm image) | Optimized images available for Raspberry Pi |
| Linux | Node.js (manual) | Requires Node.js + npm |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port mapping | Default: 80 → 3333 |
| config | Data directory path | Persistent SQLite + app data |
| config | Background images directory | Optional: custom wallpapers |

## Software-layer concerns

### Architecture

- Fastify (Node.js) backend — REST API + static file serving
- React frontend — served by Fastify
- SQLite database — stored in `/app/data`
- No external database required

### Data dirs

| Container path | Description |
|---|---|
| `/app/data` | SQLite database and app data (must be persisted) |
| `/app/public/static/media/background` | Custom background images (optional) |

### Env vars

| Var | Description | Default |
|---|---|---|
| FASTIFY_PLUGIN_TIMEOUT | Plugin init timeout in ms | 10000 |

> Set `FASTIFY_PLUGIN_TIMEOUT=0` if you see `AVV_ERR_READY_TIMEOUT` errors on slow hardware.

## Install — Docker run

```bash
docker run -d \
  --name neonlink \
  --restart unless-stopped \
  -p 80:3333 \
  -v /path/to/data:/app/data \
  -v /path/to/backgrounds:/app/public/static/media/background \
  alexscifier/neonlink:latest
```

## Install — Docker Compose

```bash
git clone https://github.com/AlexSciFier/neonlink.git
cd neonlink
# Edit docker-compose.yml to set port and volume paths
docker compose up -d
```

Default `docker-compose.yml`:
```yaml
services:
  neonlink:
    image: alexscifier/neonlink
    container_name: neonlink
    volumes:
      - ./data:/app/data
      - ./background:/app/public/static/media/background
    restart: unless-stopped
    environment:
      FASTIFY_PLUGIN_TIMEOUT: 120000
    ports:
      - "80:3333"
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data in mounted volumes is preserved across upgrades.

## Gotchas

- `AVV_ERR_READY_TIMEOUT` on startup (especially on Raspberry Pi or slow storage) — set `FASTIFY_PLUGIN_TIMEOUT=0` or a large value like `120000` in your compose/env to disable the timeout.
- `/app/data` volume must be mounted — without it, the SQLite database resets on every container restart and all bookmarks are lost.
- Background images: place `.jpg`/`.png` files in the mounted backgrounds directory; they'll appear as choices in the UI settings.
- No authentication by default — NeonLink has no built-in login. Protect it with a reverse proxy + basic auth or network-level access control if exposed.

## Links

- Source: https://github.com/AlexSciFier/neonlink
- DockerHub: https://hub.docker.com/r/alexscifier/neonlink
