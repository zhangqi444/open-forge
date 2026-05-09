# Jellysweep

Smart cleanup tool for Jellyfin media servers. Automatically removes old, unwatched movies and TV shows by analyzing viewing stats and configurable filters. Supports Sonarr/Radarr tag-based control, disk usage monitoring, user keep requests, OIDC/SSO and Jellyfin authentication, email/ntfy/web push notifications, and an optional Valkey (Redis-compatible) cache.

**Official site:** https://github.com/jon4hz/jellysweep  
**Source:** https://github.com/jon4hz/jellysweep  
**Upstream docs:** https://github.com/jon4hz/jellysweep#readme  
**Docker image:** `ghcr.io/jon4hz/jellysweep:latest`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Primary method — single container |
| Any Linux host | Docker Compose + Valkey | Adds Redis-compatible cache for high-traffic |
| Any Linux host | Docker (single container) | Minimal setup, memory cache |

**Prerequisites:** A running Jellyfin server. Requires Jellyseerr for request tracking. Sonarr, Radarr, Jellystat, or Streamystats are optional but recommended for full functionality.

---

## Inputs to Collect

### Required
| Variable | Description | Example |
|----------|-------------|---------|
| `JELLYSWEEP_JELLYFIN_URL` | URL of your Jellyfin server | `http://localhost:8096` |
| `JELLYSWEEP_JELLYFIN_API_KEY` | Jellyfin API key | generated in Jellyfin admin |
| `JELLYSWEEP_JELLYSEERR_URL` | Jellyseerr server URL | `http://localhost:5055` |
| `JELLYSWEEP_JELLYSEERR_API_KEY` | Jellyseerr API key | from Jellyseerr settings |
| `JELLYSWEEP_SESSION_KEY` | Random string for session encryption | `openssl rand -base64 32` |

### Media management (at least one required)
| Variable | Description | Example |
|----------|-------------|---------|
| `JELLYSWEEP_SONARR_URL` | Sonarr server URL | `http://localhost:8989` |
| `JELLYSWEEP_SONARR_API_KEY` | Sonarr API key | from Sonarr settings |
| `JELLYSWEEP_RADARR_URL` | Radarr server URL | `http://localhost:7878` |
| `JELLYSWEEP_RADARR_API_KEY` | Radarr API key | from Radarr settings |

### Optional — stats providers (pick one, not both)
| Variable | Description |
|----------|-------------|
| `JELLYSWEEP_JELLYSTAT_URL` + `JELLYSWEEP_JELLYSTAT_API_KEY` | Jellystat stats backend |
| `JELLYSWEEP_STREAMYSTATS_URL` + `JELLYSWEEP_STREAMYSTATS_SERVER_ID` | Streamystats backend |

### Optional — tuning
| Variable | Default | Description |
|----------|---------|-------------|
| `JELLYSWEEP_DRY_RUN` | `true` | Preview deletions without acting; set `false` only after review |
| `JELLYSWEEP_LISTEN` | `0.0.0.0:3002` | Web interface bind address |
| `JELLYSWEEP_CLEANUP_SCHEDULE` | `0 */12 * * *` | Cron schedule for cleanup runs |
| `JELLYSWEEP_CLEANUP_MODE` | `all` | `all` / `keep_episodes` / `keep_seasons` |
| `JELLYSWEEP_KEEP_COUNT` | `1` | Episodes/seasons to keep for selective modes |
| `JELLYSWEEP_SERVER_URL` | `http://localhost:3002` | Public base URL (used in notifications) |
| `JELLYSWEEP_LOG_LEVEL` | `info` | `debug` / `info` / `warn` / `error` |

---

## Software-Layer Concerns

### Docker Compose (minimal)

```yaml
services:
  jellysweep:
    image: ghcr.io/jon4hz/jellysweep:latest
    container_name: jellysweep
    restart: unless-stopped
    ports:
      - "3002:3002"
    volumes:
      - ./config.yml:/app/config.yml:ro   # optional config file
      - ./data:/app/data
      # Mount Jellyfin media paths at the same locations for disk usage monitoring:
      # - /data/movies:/data/movies:ro
      # - /data/tv:/data/tv:ro
    environment:
      - JELLYSWEEP_DRY_RUN=false
      - JELLYSWEEP_LISTEN=0.0.0.0:3002
      - JELLYSWEEP_SESSION_KEY=<generate with: openssl rand -base64 32>
      - JELLYSWEEP_JELLYFIN_URL=http://jellyfin:8096
      - JELLYSWEEP_JELLYFIN_API_KEY=<jellyfin-api-key>
      - JELLYSWEEP_JELLYSEERR_URL=http://jellyseerr:5055
      - JELLYSWEEP_JELLYSEERR_API_KEY=<jellyseerr-api-key>
      - JELLYSWEEP_SONARR_URL=http://sonarr:8989
      - JELLYSWEEP_SONARR_API_KEY=<sonarr-api-key>
      - JELLYSWEEP_RADARR_URL=http://radarr:7878
      - JELLYSWEEP_RADARR_API_KEY=<radarr-api-key>
```

### Docker Compose with Valkey cache

```yaml
services:
  jellysweep:
    image: ghcr.io/jon4hz/jellysweep:latest
    container_name: jellysweep
    restart: unless-stopped
    ports:
      - "3002:3002"
    volumes:
      - ./config.yml:/app/config.yml:ro
      - ./data:/app/data
    environment:
      - JELLYSWEEP_DRY_RUN=false
      - JELLYSWEEP_LISTEN=0.0.0.0:3002
      - JELLYSWEEP_CACHE_TYPE=redis
      - JELLYSWEEP_CACHE_REDIS_URL=valkey:6379
    depends_on:
      - valkey

  valkey:
    image: valkey/valkey:8-alpine
    container_name: jellysweep-valkey
    restart: unless-stopped
```

### Configuration file (config.yml)

Library-level filter configuration **must** use the config file — it cannot be set via environment variables:

```yaml
dry_run: false
listen: "0.0.0.0:3002"
cleanup_schedule: "0 */12 * * *"
cleanup_mode: "keep_seasons"
keep_count: 1
session_key: "your-session-key"
server_url: "http://localhost:3002"

jellyfin:
  url: "http://localhost:8096"
  api_key: "your-jellyfin-api-key"

auth:
  jellyfin:
    enabled: true
  # oidc:
  #   enabled: true
  #   issuer: "https://your-sso.example.com/..."
  #   client_id: "..."
  #   client_secret: "..."
  #   redirect_url: "http://localhost:3002/auth/oidc/callback"
  #   admin_group: "jellyfin-admins"
```

### Data directory

- Database stored at `./data/jellysweep.db` (SQLite)
- Back up the `data/` directory

### Disk usage monitoring

To enable disk usage-based adaptive cleanup, mount your Jellyfin media paths **at the same paths** inside the Jellysweep container:

```yaml
    volumes:
      - /data/movies:/data/movies:ro
      - /data/tv:/data/tv:ro
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **Always start with `JELLYSWEEP_DRY_RUN=true`** and review the dashboard before enabling real deletions.
- **Library filters cannot be set via environment variables** — use `config.yml` for per-library filter configuration.
- Only one stats backend (Jellystat **or** Streamystats) can be configured at a time.
- At least one of Sonarr or Radarr must be configured.
- When using Jellyfin authentication, all Jellyfin admins automatically receive admin access in Jellysweep.
- `JELLYSWEEP_SECURE_COOKIES=true` by default — disable only for non-HTTPS local development.
- Items already marked for deletion are not re-evaluated through filters; filter changes only affect new candidates.
- To reset all Sonarr/Radarr tags set by Jellysweep: `docker compose exec jellysweep ./jellysweep reset`

---

**Upstream README:** https://github.com/jon4hz/jellysweep#readme
