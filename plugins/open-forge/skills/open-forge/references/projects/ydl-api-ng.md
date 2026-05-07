---
name: ydl-api-ng
description: ydl_api_ng recipe for open-forge. Simple REST API for yt-dlp to queue and manage media downloads on a remote server. Python + Redis + yt-dlp. Docker Compose. GPL-3.0. Source: https://github.com/Totonyus/ydl_api_ng
---

# ydl_api_ng

Simple REST API wrapper around yt-dlp (youtube-dl successor). Lets you trigger and manage media downloads on a remote server via HTTP requests. Supports parallel downloads, scheduled downloads (programmations), hooks, cookies for authenticated sites, and a Redis-backed task queue. Python. Docker Compose. GPL-3.0 licensed.

Also works as a backend for browser userscripts or iOS Shortcuts to send URLs for download from any device.

Upstream: https://github.com/Totonyus/ydl_api_ng | Docker Hub: https://hub.docker.com/r/totonyus/ydl_api_ng

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Official method; includes Redis |
| Any | Docker run + external Redis | Manual compose alternative |
| Linux | pip (without Docker) | See doc/001_Installation_without_docker.md |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port | Default: 5011 (maps to container port 80) |
| config | UID / GID | Host user/group ID for file ownership of downloads (default: 1000:1000) |
| config (optional) | NB_WORKERS | Number of parallel downloads (default: set in worker.ini) |
| config (optional) | LOG_LEVEL | Logging verbosity (default: error) |
| config (optional) | DISABLE_REDIS | Set false to use Redis (default); true to disable |
| config (optional) | FORCE_YTDLP_VERSION | Pin yt-dlp version (highly discouraged) |

## Software-layer concerns

### Volumes

| Host path | Container path | Description |
|---|---|---|
| ./downloads | /app/downloads | Downloaded media files |
| ./params | /app/params | params.ini and hook files (generated on first run) |
| ./logs | /app/logs | Application logs |
| ./cookies | /app/persistant_cookies | Cookie files for authenticated sites |
| ./data | /app/data | Programmations (scheduled downloads) SQLite database |
| /etc/localtime | /etc/localtime:ro | Sync timezone from host |

### Key notes

- params.ini is auto-generated on first launch into the ./params/ volume; edit it to configure yt-dlp options and download paths
- Redis required by default for task queuing; DISABLE_REDIS=true for a simpler setup without queueing
- UID/GID: downloaded files are owned by the container user; set UID/GID to match your host user to avoid permission issues

## Install -- Docker Compose

```yaml
version: "3.1"
services:
  ydl_api_ng:
    container_name: ydl_api_ng
    image: totonyus/ydl_api_ng
    restart: unless-stopped
    depends_on:
      - ydl_api_ng_redis
    ports:
      - 5011:80
    volumes:
      - ./downloads:/app/downloads
      - ./params:/app/params
      - ./logs:/app/logs
      - ./cookies:/app/persistant_cookies
      - ./data:/app/data
      - /etc/localtime:/etc/localtime:ro
    environment:
      - UID=1000
      - GID=1000
      - NB_WORKERS=5
      - LOG_LEVEL=error
      - DISABLE_REDIS=false
    networks:
      - ydl_api_ng

  ydl_api_ng_redis:
    container_name: ydl_api_ng_redis
    image: redis
    restart: unless-stopped
    networks:
      - ydl_api_ng
    volumes:
      - /etc/localtime:/etc/localtime:ro

networks:
  ydl_api_ng:
```

```bash
docker compose up -d
# API at http://yourserver:5011
```

## API usage

```bash
# Download a URL with default settings
curl -X POST http://yourserver:5011/api/download \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"}'
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
# yt-dlp itself is auto-updated inside the container on restart
```

## Gotchas

- UID/GID mismatch: if downloaded files are owned by root or an unknown user, set UID and GID env vars to match the host user who needs to access the files.
- params.ini is generated on first run: if you mount an empty ./params/ directory, the container creates a default params.ini on first start. Edit it to configure yt-dlp quality preferences, output templates, and paths.
- FORCE_YTDLP_VERSION: only use when a new yt-dlp version breaks something. Pinning to an old version means missing bug fixes and site compatibility updates.
- Cookies: place Netscape-format cookie files in ./cookies/ and reference them in params.ini for downloading from sites that require login.

## Links

- Source: https://github.com/Totonyus/ydl_api_ng
- Docker Hub: https://hub.docker.com/r/totonyus/ydl_api_ng
- Install docs: https://github.com/Totonyus/ydl_api_ng/tree/main/doc
