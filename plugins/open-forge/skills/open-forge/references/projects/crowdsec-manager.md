---
name: crowdsec-manager-project
description: CrowdSec Manager recipe for open-forge. Web UI for managing CrowdSec decisions, alerts, allowlists, scenarios, hub, logs, backups, and Traefik integration. Two deployment modes: Pangolin (full Traefik+Pangolin stack) and Independent (CrowdSec-only). Mobile app available. Upstream: https://github.com/hhftechnology/crowdsec_manager
---

# CrowdSec Manager

A web-based management interface for CrowdSec. Manage decisions, analyze alerts, maintain allowlists, browse and install hub components (collections, parsers, scenarios), view logs, run backups, and integrate with Traefik dynamic config. Mobile apps available for iOS and Android.

Upstream: <https://github.com/hhftechnology/crowdsec_manager> | Docs: <https://crowdsec-manager.hhf.technology>

Two deployment modes:
- **Pangolin** (`hhftechnology/crowdsec-manager:latest`) — full stack addon for an existing Traefik+Pangolin setup
- **Independent** (`hhftechnology/crowdsec-manager:independent`) — standalone CrowdSec-only; no Traefik dependency

## Compatible combos

| Mode | Infra | Notes |
|---|---|---|
| Independent | Any Linux host | CrowdSec + Manager; self-contained |
| Pangolin | Traefik + Pangolin stack | Add-on to existing Pangolin/Traefik deployment |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Deployment mode: Pangolin or Independent?" | Determines image tag and compose structure |
| preflight | "Host port for web UI?" | Default: `8080` |
| config (Pangolin) | "Path to Pangolin config folder?" | Mounted at `/app/config` |
| config (Pangolin) | "Path to Pangolin docker-compose.yml?" | Mounted at `/app/docker-compose.yml` |
| config (Pangolin) | "Traefik dynamic config path?" | e.g. `/etc/traefik/dynamic_config.yml` |
| config (Pangolin) | "Traefik static config path?" | e.g. `/etc/traefik/traefik_config.yml` |
| config (Pangolin) | "CrowdSec container name?" | `TRAEFIK_CONTAINER_NAME` env var |

## Software-layer concerns

### Images

```
hhftechnology/crowdsec-manager:latest       # Pangolin mode
hhftechnology/crowdsec-manager:independent  # Independent mode
```

Docker Hub: <https://hub.docker.com/r/hhftechnology/crowdsec-manager>

### Compose — Independent (CrowdSec only)

```yaml
services:
  crowdsec-manager:
    image: hhftechnology/crowdsec-manager:independent
    container_name: crowdsec-manager
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - ENVIRONMENT=production
      - CONFIG_DIR=/app/config
      - DATABASE_PATH=/app/data/settings.db
      - INCLUDE_CROWDSEC=true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./config:/app/config
      - ./logs/app:/app/logs
      - ./data:/app/data
    networks:
      - crowdsec-network
    depends_on:
      - crowdsec

  crowdsec:
    image: crowdsecurity/crowdsec:latest
    container_name: crowdsec
    environment:
      - COLLECTIONS=crowdsecurity/linux
    volumes:
      - ./config/crowdsec/acquis.yaml:/etc/crowdsec/acquis.yaml:ro
      - crowdsec-db:/var/lib/crowdsec/data/
      - crowdsec-config:/etc/crowdsec/
    networks:
      - crowdsec-network

networks:
  crowdsec-network:
    driver: bridge

volumes:
  crowdsec-db:
  crowdsec-config:
```

### Compose — Pangolin addon (partial — add to existing Pangolin stack)

```yaml
  crowdsec-manager:
    image: hhftechnology/crowdsec-manager:latest
    container_name: crowdsec-manager
    restart: unless-stopped
    environment:
      - PORT=8080
      - ENVIRONMENT=production
      - TRAEFIK_DYNAMIC_CONFIG=/etc/traefik/dynamic_config.yml
      - TRAEFIK_CONTAINER_NAME=traefik
      - TRAEFIK_STATIC_CONFIG=/etc/traefik/traefik_config.yml
      - CROWDSEC_METRICS_URL=http://crowdsec:6060/metrics
      - ALERT_LIST_LIMIT=5000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /root/config:/app/config           # Pangolin config folder
      - /root/docker-compose.yml:/app/docker-compose.yml
      - ./crowdsec-manager/backups:/app/backups
      - ./crowdsec-manager/data:/app/data
    depends_on:
      crowdsec:
        condition: service_healthy
```

> Source: upstream README — <https://github.com/hhftechnology/crowdsec_manager>

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `8080` | Web UI port |
| `ENVIRONMENT` | `production` | `production` or `development` |
| `CONFIG_DIR` | `/app/config` | Config directory path inside container |
| `DATABASE_PATH` | `/app/data/settings.db` | SQLite settings database path |
| `INCLUDE_CROWDSEC` | `true` | Include CrowdSec management features |
| `TRAEFIK_DYNAMIC_CONFIG` | — | Path to Traefik dynamic config (Pangolin mode) |
| `TRAEFIK_STATIC_CONFIG` | — | Path to Traefik static config (Pangolin mode) |
| `TRAEFIK_CONTAINER_NAME` | — | Traefik container name for restart triggers (Pangolin mode) |
| `CROWDSEC_METRICS_URL` | — | CrowdSec metrics endpoint, e.g. `http://crowdsec:6060/metrics` |
| `ALERT_LIST_LIMIT` | — | Max alerts to fetch/display |
| `BACKUP_DIR` | `/app/backups` | Backup output directory |
| `RETENTION_DAYS` | `60` | How many days to retain backups |

### Features

- **Decisions** — view, add, delete CrowdSec IP bans and captcha decisions
- **Alerts analysis** — filter, inspect, and analyze security alerts with country/scenario breakdowns
- **Allowlists** — manage IP/range/CIDR allowlists
- **Hub** — browse and install CrowdSec collections, parsers, scenarios, AppSec rules
- **Scenarios** — manage active detection scenarios
- **Logs** — view CrowdSec and Traefik logs live
- **Backups** — automated and manual config backups with retention
- **Traefik integration** — read/edit dynamic config, view access logs
- **Terminal** — container shell access from the web UI
- **Mobile app** — iOS (coming soon) and Android apps; Pangolin (token) and Basis (direct URL) connection modes

### Setup after first run

```bash
mkdir -p ./config/crowdsec ./logs/app ./data
# Create acquis.yaml for CrowdSec to know what logs to parse:
cat > ./config/crowdsec/acquis.yaml << 'EOF'
filenames:
  - /var/log/auth.log
  - /var/log/syslog
labels:
  type: syslog
EOF
docker compose up -d
curl http://localhost:8080/api/health/stack
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data in `./data`, `./config`, and named volumes persists across upgrades.

## Gotchas

- **Two separate images** — `:latest` (Pangolin) and `:independent` are different builds. Using the wrong one results in missing Traefik features or broken Pangolin integration.
- **Docker socket required** — the manager needs `/var/run/docker.sock` to restart containers and manage the stack.
- **`acquis.yaml` required for CrowdSec** — without it, CrowdSec starts but doesn't parse any logs. Create a minimal one pointing at your log files before first run.
- **Pangolin mode mounts external files** — it reads your existing Pangolin `docker-compose.yml` and config. Paths must match exactly what's on the host.
- **No built-in authentication in UI** — the web UI has no login. Front with a reverse proxy auth layer (Authelia, Traefik ForwardAuth, nginx basic auth) before exposing.
- **`CROWDSEC_METRICS_URL` must use container name** — in a Docker network, use `http://crowdsec:6060/metrics`, not `localhost`.

## Links

- Upstream README: <https://github.com/hhftechnology/crowdsec_manager>
- Documentation: <https://crowdsec-manager.hhf.technology>
- Docker Hub: <https://hub.docker.com/r/hhftechnology/crowdsec-manager>
- Discord: <https://discord.gg/HDCt9MjyMJ>
- CrowdSec: <https://crowdsec.net>
