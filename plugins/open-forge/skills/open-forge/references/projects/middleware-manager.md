---
name: middleware-manager-project
description: Traefik/Pangolin Middleware Manager recipe for open-forge. UI-driven middleware, router, service, plugin, and mTLS management for Traefik. Works standalone with Traefik or alongside Pangolin. Upstream: https://github.com/hhftechnology/middleware-manager
---

# Middleware Manager

A comprehensive UI for managing Traefik middlewares, routers, services, plugins, and mTLS — all from a single dashboard. Supports two data-source modes: **Pangolin** (recommended when Pangolin already manages Traefik) or **standalone Traefik**. Upstream: <https://github.com/hhftechnology/middleware-manager>. Docs: <https://middleware-manager.hhf.technology>.

The container must stay **running** to keep override middlewares deployed. Written in Go (API) + React/Vite (UI).

## Compatible combos

| Infra | Data source | Notes |
|---|---|---|
| Any Linux host with Traefik | Standalone Traefik | Set `ACTIVE_DATA_SOURCE=traefik` |
| Any Linux host with Pangolin | Pangolin | Set `ACTIVE_DATA_SOURCE=pangolin` (recommended path) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Do you use Pangolin or standalone Traefik?" | Determines `ACTIVE_DATA_SOURCE` |
| preflight | "What port should Middleware Manager bind to?" | Default: `3456` |
| preflight | "Path to Traefik static config dir on host?" | Mounted at the same path in the container; e.g. `/etc/traefik` or `./config/traefik` |
| preflight | "Path to Traefik dynamic conf output dir?" | Mounted as `TRAEFIK_CONF_DIR`; e.g. `./config/traefik/conf` |
| preflight (Pangolin mode) | "Pangolin API URL?" | Default: `http://pangolin:3001/api/v1` |
| preflight (Traefik mode) | "Traefik API URL?" | e.g. `http://traefik:8080` |

## Software-layer concerns

### Image

```
hhftechnology/middleware-manager:latest
```

Docker Hub: <https://hub.docker.com/r/hhftechnology/middleware-manager>

### Compose — Option A: Pangolin data source

```yaml
services:
  middleware-manager:
    image: hhftechnology/middleware-manager:latest
    restart: unless-stopped
    volumes:
      - ./data:/data
      - ./config/middleware-manager:/app/config
      - ./config/traefik:/etc/traefik        # must match Traefik's static config dir
    environment:
      - ACTIVE_DATA_SOURCE=pangolin
      - PANGOLIN_API_URL=http://pangolin:3001/api/v1
      - TRAEFIK_STATIC_CONFIG_PATH=/etc/traefik/traefik_config.yml
      - TRAEFIK_CONF_DIR=/conf
      - DB_PATH=/data/middleware.db
      - PORT=3456
    ports:
      - "3456:3456"
    networks:
      - pangolin

networks:
  pangolin:
    external: true   # connect to existing Pangolin network
```

### Compose — Option B: Standalone Traefik data source

```yaml
services:
  middleware-manager:
    image: hhftechnology/middleware-manager:latest
    restart: unless-stopped
    volumes:
      - ./data:/data
      - ./config/traefik/conf:/conf
    environment:
      - ACTIVE_DATA_SOURCE=traefik
      - TRAEFIK_API_URL=http://traefik:8080
      - TRAEFIK_CONF_DIR=/conf
      - DB_PATH=/data/middleware.db
      - PORT=3456
    ports:
      - "3456:3456"
```

> Source: upstream README — <https://github.com/hhftechnology/middleware-manager>

### Key environment variables

| Variable | Required | Purpose |
|---|---|---|
| `ACTIVE_DATA_SOURCE` | ✅ | `pangolin` or `traefik` |
| `PANGOLIN_API_URL` | Pangolin only | Pangolin API endpoint |
| `TRAEFIK_API_URL` | Traefik only | Traefik API endpoint |
| `TRAEFIK_STATIC_CONFIG_PATH` | Pangolin mode | Full path to Traefik's static config YAML inside container |
| `TRAEFIK_CONF_DIR` | ✅ | Directory where Middleware Manager writes Traefik dynamic config |
| `DB_PATH` | ✅ | SQLite database path inside container |
| `PORT` | ✅ | UI/API listen port (default `3456`) |

### Volume mounts

| Host path | Container path | Purpose |
|---|---|---|
| `./data` | `/data` | SQLite DB persistence |
| `./config/middleware-manager` | `/app/config` | App config |
| `./config/traefik` | `/etc/traefik` (or custom) | Traefik static config directory (Pangolin mode) |
| `./config/traefik/conf` | `/conf` | Traefik dynamic config output (both modes) |

### What Middleware Manager can do

- Discover resources from Pangolin or Traefik and safely override routers/services
- Create and assign Traefik middlewares with priorities and templates
- Define custom services (load balancer, weighted, mirroring, failover)
- Install/manage Traefik plugins (writes to static config; restarts Traefik as needed)
- Enable mTLS via the `mtlswhitelist` plugin with per-resource rules
- Inspect Traefik routers/services/middlewares via built-in explorer

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

The SQLite DB in `./data` persists all configurations across upgrades.

## Gotchas

- **Container must keep running** — override middlewares are only active while the container is up. Stopping it removes the overrides from Traefik.
- **`TRAEFIK_CONF_DIR` must be writable and match Traefik's dynamic config provider path** — misconfiguration means Traefik never picks up the overrides.
- **Pangolin network must exist before `docker compose up`** — the `pangolin` network is marked `external: true`; create it first or remove the `external` flag for standalone testing.
- **Traefik static config changes (for plugin installs) require a Traefik restart** — Middleware Manager handles this automatically when using the plugin management UI.
- **The app does not disturb the original Traefik API** — it creates a separate override layer. Reverting to the original Traefik config restores default routers/services.
- **Changing `ACTIVE_DATA_SOURCE` after initial setup may leave stale data** — if switching from Pangolin to standalone Traefik (or vice versa), clear `./data/middleware.db`.

## Links

- Upstream README + quick start: <https://github.com/hhftechnology/middleware-manager>
- Documentation: <https://middleware-manager.hhf.technology>
- Docker Hub: <https://hub.docker.com/r/hhftechnology/middleware-manager>
- Discord: <https://discord.gg/HDCt9MjyMJ>
