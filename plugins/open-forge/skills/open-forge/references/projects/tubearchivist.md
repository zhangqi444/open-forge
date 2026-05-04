---
name: tubearchivist
description: Recipe for TubeArchivist — self-hosted YouTube archive and media server.
---

# TubeArchivist

Self-hosted YouTube archive: subscribe to channels, download videos via yt-dlp, index with metadata, and browse/play through a web UI. Backed by Elasticsearch (search + metadata), Redis (cache/queue), and a custom Nginx-served frontend. Upstream: <https://github.com/tubearchivist/tubearchivist>. Docs: <https://docs.tubearchivist.com>. License: GPL-3.0. ~15K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/tubearchivist/tubearchivist#installing> | ✅ | Recommended. Three-container stack. |
| Unraid | <https://docs.tubearchivist.com/installation/unraid/> | Community | Unraid community app. |
| Synology | <https://docs.tubearchivist.com/installation/synology/> | Community | Synology NAS DSM. |
| Podman | <https://docs.tubearchivist.com/installation/podman/> | Community | Rootless Podman alternative. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| software | "What host/IP should TubeArchivist be accessed at?" | URL with protocol + port (e.g. `http://tubearchivist.local:8000`) | All. Used in `TA_HOST`. |
| software | "Initial admin username?" | String | All |
| software | "Initial admin password?" | Sensitive string | All |
| software | "Elasticsearch password?" | Sensitive string | All. Must match in both TA and ES containers. |
| software | "Timezone?" | TZ string (e.g. `America/New_York`) | All |
| software | "Host UID/GID for file ownership?" | Integer pair (default 1000/1000) | Optional; prevents permission issues on video files |

## Software-layer concerns

### Docker Compose

```yaml
services:
  tubearchivist:
    container_name: tubearchivist
    restart: unless-stopped
    image: bbilly1/tubearchivist
    ports:
      - 8000:8000
    volumes:
      - media:/youtube
      - cache:/cache
    environment:
      - ES_URL=http://archivist-es:9200
      - REDIS_CON=redis://archivist-redis:6379
      - HOST_UID=1000
      - HOST_GID=1000
      - TA_HOST=http://tubearchivist.local:8000   # set your real host
      - TA_USERNAME=tubearchivist
      - TA_PASSWORD=verysecret                     # change this
      - ELASTIC_PASSWORD=verysecret               # change this; must match archivist-es
      - TZ=America/New_York
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/health/"]
      interval: 2m
      timeout: 10s
      retries: 3
      start_period: 30s
    depends_on:
      - archivist-es
      - archivist-redis

  archivist-redis:
    image: redis/redis-stack-server
    container_name: archivist-redis
    restart: unless-stopped
    expose:
      - "6379"
    volumes:
      - redis:/data
    depends_on:
      - archivist-es

  archivist-es:
    image: bbilly1/tubearchivist-es     # amd64 only; use elastic/elasticsearch:8.x for arm64
    container_name: archivist-es
    restart: unless-stopped
    environment:
      - "ELASTIC_PASSWORD=verysecret"   # must match TA_PASSWORD above
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
      - "xpack.security.enabled=true"
      - "discovery.type=single-node"
      - "path.repo=/usr/share/elasticsearch/data/snapshot"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es:/usr/share/elasticsearch/data
    expose:
      - "9200"

volumes:
  media:
  cache:
  redis:
  es:
```

### Key environment variables

| Variable | Required | Description |
|---|---|---|
| `TA_HOST` | ✅ | Public URL of the TubeArchivist UI — must include protocol + port |
| `TA_USERNAME` | ✅ | Initial admin username |
| `TA_PASSWORD` | ✅ | Initial admin password (also accepts `TA_PASSWORD_FILE`) |
| `ELASTIC_PASSWORD` | ✅ | Elasticsearch password (must match ES container) |
| `REDIS_CON` | ✅ | Redis connection string |
| `ES_URL` | ✅ | Elasticsearch URL |
| `TZ` | ✅ | Timezone for the scheduler |
| `HOST_UID` / `HOST_GID` | Optional | Set to match the host user owning the media mount |
| `TA_ENABLE_AUTH_PROXY` | Optional | Enable forward-auth header support for reverse proxy SSO |

### Data volumes

| Volume | Purpose |
|---|---|
| `media` → `/youtube` | Downloaded video files |
| `cache` → `/cache` | Thumbnails, temp files |
| `redis` | Redis persistence |
| `es` | Elasticsearch index |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Elasticsearch may run a migration on first start after an upgrade — monitor `docker compose logs archivist-es`.

## Gotchas

- **arm64 / Apple Silicon**: `bbilly1/tubearchivist-es` is amd64-only. Use `elastic/elasticsearch:8.x` on ARM (see upstream docs for config differences).
- **Memory**: Elasticsearch needs 2+ GB RAM for a small setup; 4+ GB for a medium/large archive.
- **`TA_HOST` must be accurate**: TubeArchivist generates absolute URLs and API callbacks using this value. Getting it wrong breaks channel art, downloads, etc.
- **Password sync**: `ELASTIC_PASSWORD` in the TA container must match what Elasticsearch was initialized with. Changing it after first boot requires re-initializing Elasticsearch.
- **Bind-mount permission errors**: If using host bind mounts instead of named volumes for `es`, ensure the directory is owned by UID 1000. See upstream README.
- **No built-in reverse proxy**: Use Nginx/Caddy/Traefik in front for HTTPS in production.

## Links

- GitHub: <https://github.com/tubearchivist/tubearchivist>
- Docs: <https://docs.tubearchivist.com>
- Docker Hub: <https://hub.docker.com/r/bbilly1/tubearchivist>
- Discord: <https://www.tubearchivist.com/discord>
- Browser extension: <https://github.com/tubearchivist/browser-extension>
- Jellyfin plugin: <https://github.com/tubearchivist/tubearchivist-jf-plugin>
