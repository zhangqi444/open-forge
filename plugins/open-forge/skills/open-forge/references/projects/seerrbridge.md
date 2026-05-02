---
name: seerrbridge
description: SeerrBridge recipe for open-forge. Browser-automation bridge connecting Jellyseerr/Overseerr to Debrid Media Manager + Real-Debrid for automated media fetching. Based on upstream docs at https://github.com/Woahai321/SeerrBridge.
---

# SeerrBridge

Browser-automation tool that connects Jellyseerr/Overseerr to Debrid Media Manager via Selenium, automatically searching and fetching torrents to Real-Debrid when a media request is made. Includes a built-in Nuxt 4/Vue 3 dashboard ("Darth Vadarr"), MySQL persistence, queue management, TV show subscriptions, and custom regex filtering. Upstream: <https://github.com/Woahai321/SeerrBridge>.

> ⚠️ **BETA software.** Requires a Real-Debrid subscription and an active Overseerr/Jellyseerr instance. Uses Selenium browser automation — not a direct API integration.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux x86-64 Docker host | Docker Compose (single unified container) | Recommended — all services (MySQL + Python backend + Nuxt frontend) in one image |
| Windows x86-64 Docker host | Docker Compose | Tested and working per upstream |
| Linux/Windows x86-64 | `docker run` single command | Quickest trial — see upstream quick start |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Overseerr/Jellyseerr webhook URL?" | SeerrBridge listens for webhook events from Overseerr; configure in Overseerr → Settings → Notifications → Webhook |
| preflight | "Real-Debrid API key?" | Configured via web dashboard at `http://<host>:3777` after deploy |
| preflight | "Debrid Media Manager session/credentials?" | Configured via web dashboard; Selenium uses these to automate DMM |
| security | "MySQL root password?" | Default `seerrbridge_root` — change for production; set `MYSQL_ROOT_PASSWORD` |
| security | "MySQL DB password?" | Default `seerrbridge` — change; set `DB_PASSWORD` |
| network | "Should the dashboard be exposed publicly?" | Default is local only; add reverse proxy + auth before exposing |
| advanced | "Run browser in headless mode?" | Default `true` (`HEADLESS_MODE`); set `false` to see Selenium browser (debug only) |

## Software-layer concerns

**Ports** (all exposed from the single container):

| Port (host) | Port (container) | Purpose |
|---|---|---|
| `3777` | `3777` | Nuxt frontend dashboard |
| `8777` | `8777` | SeerrBridge Python API |
| `8778` | `8778` | Setup API server |
| `3307` | `3306` | MySQL (exposed on `3307` to avoid conflicts with local MySQL) |

**Key env vars** (from upstream `docker-compose.yml`):

| Variable | Default | Purpose |
|---|---|---|
| `MYSQL_ROOT_PASSWORD` | `seerrbridge_root` | MySQL root password |
| `DB_HOST` | `localhost` | MySQL host (internal) |
| `DB_NAME` | `seerrbridge` | Database name |
| `DB_USER` | `seerrbridge` | Database user |
| `DB_PASSWORD` | `seerrbridge` | Database password |
| `NUXT_PORT` | `3777` | Dashboard port |
| `SEERRBRIDGE_URL` | `http://localhost:8777` | Backend API URL |

> Most configuration (API keys, Overseerr URL, Real-Debrid token, regex filters) is managed via the web dashboard and persisted to `./data/.env`.

**Data volumes:**

| Host path | Purpose |
|---|---|
| `seerrbridge_mysql_data` | MySQL database persistence |
| `./logs` | Application logs |
| `./data` | App data including `.env` config file |

## Upgrade procedure

1. Pull new image: `docker compose pull` or `docker pull ghcr.io/woahai321/seerrbridge:latest`
2. Restart: `docker compose down && docker compose up -d`
3. Config in `./data/.env` persists across upgrades.
4. Check health: `docker logs seerrbridge`

## Gotchas

- Requires a **Real-Debrid** paid subscription — no support for AllDebrid or TorBox.
- Selenium browser automation means the container is heavy (~Chromium included) and startup takes up to 120 seconds.
- Default passwords are insecure — **always change `MYSQL_ROOT_PASSWORD` and `DB_PASSWORD` before exposing publicly**.
- The `./data/.env` file is written by the setup UI; don't hand-edit while the container is running.
- `HEADLESS_MODE=false` launches a visible Chrome window — only use for debugging, not production.
- TV show subscriptions track episodes individually; requires correct Overseerr webhook setup.

## Links

- GitHub: <https://github.com/Woahai321/SeerrBridge>
- Overseerr: <https://overseerr.dev/>
- Jellyseerr: <https://github.com/Fallenbagel/jellyseerr>
- Debrid Media Manager: <https://github.com/debridmediamanager/debrid-media-manager>
- Real-Debrid: <https://real-debrid.com/>
