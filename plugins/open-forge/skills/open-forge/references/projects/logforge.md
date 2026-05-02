---
name: logforge
description: LogForge recipe for open-forge. Self-hosted Docker container monitoring, alerting, and safe auto-remediation. Based on upstream docs at https://github.com/log-forge/logforge.
---

# LogForge

Self-hosted monitoring, alerting, and remediation platform for Docker containers. Provides live log streaming, rules-based alerting (keywords, container events, performance thresholds), and safe auto-remediation (restart/stop/kill/start/run scripts) with built-in cooldowns and rate limits. No external metrics stack required. Upstream: <https://github.com/log-forge/logforge>. Website: <https://log-forge.github.io/logforgeweb/>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Docker host (VPS, home server) | Docker Compose (multi-container) | Standard deploy — frontend + backend + alert-engine + notifier + auto-update |
| Any Docker host | Docker Compose (custom ports via `.env`) | Rename container names / change exposed ports via `.env` |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "What port should the LogForge UI be accessible on?" | Default `3008` → `LOGFORGE_FRONTEND_PORT` |
| preflight | "What port for the Notifier web UI?" | Default `8087` → `NOTIFIER_WEB_PORT` |
| preflight | "What port for the Alert Engine UI?" | Default `3033` → `ALERT_ENGINE_FRONTEND_PORT` |
| preflight | "Enable auto-updates?" | Default `true` → `AUTO_UPDATE` (set `false` to disable Watchtower-based updates) |
| notifications | "Which notification channels to configure? (Email / Discord / Telegram / Slack / Gotify)" | Configured in the Notifier UI after deploy |

## Software-layer concerns

**Container names / ports** (configurable via `.env` file in repo root):

| Variable | Default | Purpose |
|---|---|---|
| `LOGFORGE_BACKEND_CONTAINER_NAME` | `logforge-backend` | Backend container name |
| `LOGFORGE_FRONTEND_CONTAINER_NAME` | `logforge-frontend` | Frontend container name |
| `ALERT_ENGINE_BACKEND_CONTAINER_NAME` | `logforge-alert-backend` | Alert engine backend |
| `ALERT_ENGINE_FRONTEND_CONTAINER_NAME` | `logforge-alert-frontend` | Alert engine frontend |
| `AUTOUPDATE_SERVICE_NAME` | `logforge-autoupdate` | Auto-update (Watchtower-based) |
| `NOTIFIER_SERVICE_CONTAINER_NAME` | `logforge-notifier` | Notification dispatcher |
| `LOGFORGE_FRONTEND_PORT` | `3008` | UI port (bound to 127.0.0.1) |
| `NOTIFIER_WEB_PORT` | `8087` | Notifier UI port |
| `ALERT_ENGINE_FRONTEND_PORT` | `3033` | Alert engine UI port |
| `AUTO_UPDATE` | `true` | Enable/disable auto-updates |

**Docker socket access:** The backend and auto-update containers mount `/var/run/docker.sock` — required for container discovery and remediation. Ensure the deploying user has Docker socket access.

**Data volumes:**

| Volume | Purpose |
|---|---|
| `logforge_core_data` | Backend core state |
| `logforge_notifier_data` | Notifier config and history |
| `logforge_alert_engine_data` | Alert rules and history |

**Network:** All containers share `logforge-network` (bridge). Frontend ports are bound to `127.0.0.1` by default — expose via reverse proxy for remote access.

## Upgrade procedure

1. Pull latest images: `docker compose pull`
2. Restart: `docker compose down && docker compose up -d`
3. Or leave `AUTO_UPDATE=true` — the `logforge-autoupdate` service handles rolling updates automatically.

## Gotchas

- The backend requires Docker socket access — running without it will prevent container discovery.
- Ports are bound to `127.0.0.1` by default; add a reverse proxy (Nginx/Caddy/Traefik) for external access.
- `AUTO_UPDATE=true` is strongly recommended by upstream — the auto-update service uses Watchtower-compatible labels.
- Alert rules with auto-remediation (restart/stop/run script) include built-in cooldowns; review rate limits before enabling in production.
- Interactive terminal and filesystem viewer features require the backend to reach the target container via Docker API.

## Links

- GitHub: <https://github.com/log-forge/logforge>
- Website: <https://log-forge.github.io/logforgeweb/>
