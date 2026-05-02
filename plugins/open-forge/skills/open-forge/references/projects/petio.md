---
name: petio
description: Petio recipe for open-forge. Plex companion app for media requests, reviews, and discovery. Based on upstream docs at https://docs.petio.tv.
---

# Petio

Companion request-management app for Plex. Lets users request, review, and discover movies and TV shows from your Plex server. React/Redux frontend, Node.js + Express API, MongoDB backend. Upstream: <https://github.com/petio-team/petio>. Docs: <https://docs.petio.tv>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Docker host (VPS, home server) | Docker Compose | Recommended — petio + MongoDB via `docker-compose.yml` from upstream |
| Any Linux host | Binary (standalone) | Requires local MongoDB; see upstream docs for Linux/macOS/Windows binary guides |
| Windows | Binary | Requires local MongoDB; see <https://docs.petio.tv/install-guides/windows> |
| macOS | Binary | See <https://docs.petio.tv/install-guides/macos> |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "What host port for Petio?" | Default `7777` |
| preflight | "What timezone (TZ)?" | e.g. `America/New_York`; defaults to `Etc/UTC` |
| preflight | "UID/GID to run the container as?" | Default `1000:1000` in upstream compose |
| config | "Plex server URL and token?" | Set during first-time web setup at `http://<host>:7777` |
| config | "Sonarr URL and API key?" | Optional — for TV show downloads |
| config | "Radarr URL and API key?" | Optional — for movie downloads |
| config | "SMTP settings for email notifications?" | Optional; configured in Petio admin panel |

## Software-layer concerns

**Data directories / volumes** (from upstream `docker-compose.yml`):

| Host path | Container path | Purpose |
|---|---|---|
| `./config` | `/app/api/config` | Petio config files |
| `./logs` | `/app/logs` | Application logs |
| `./db` | `/data/db` | MongoDB data |

**Ports:**
- `7777` — Petio web UI and API
- `27017` — MongoDB (typically internal only; remove port mapping in production)

**Services in compose:**
- `petio` — main app container (`ghcr.io/petio-team/petio:latest`)
- `mongo` — MongoDB (`mongo:latest`)

Both run as UID/GID `1000:1000` by default — ensure volume directories are owned accordingly:
```bash
mkdir -p config logs db
chown -R 1000:1000 config logs db
```

## Upgrade procedure

1. Pull updated images: `docker compose pull`
2. Restart: `docker compose down && docker compose up -d`
3. Check logs: `docker logs petio`
4. Config files in `./config` persist across upgrades.

## Gotchas

- Petio requires a running Plex Media Server — it does not replace or bundle Plex.
- MongoDB must be accessible before Petio starts; the `depends_on: mongo` in compose handles ordering.
- Removing the MongoDB port mapping (`27017:27017`) is recommended for production to avoid exposing the database.
- Running as `user: 1000:1000` requires the volume directories to exist and be writable by that UID/GID before starting.
- First-time setup is done via the web UI at `http://<host>:7777` — the initial admin account is created there.

## Links

- GitHub: <https://github.com/petio-team/petio>
- Docs: <https://docs.petio.tv>
- Docker install guide: <https://docs.petio.tv/install-guides/docker>
- Configuration guide: <https://docs.petio.tv/configuration/first-time-setup>
- FAQ: <https://docs.petio.tv/troubleshooting/troubleshooting-faq>
