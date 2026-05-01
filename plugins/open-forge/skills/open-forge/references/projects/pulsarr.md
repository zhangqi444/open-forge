# Pulsarr

**Real-time Plex watchlist monitoring and routing — bridges Plex watchlists with Sonarr and Radarr for automated media acquisition with approval workflows, quotas, and notifications via Discord, Plex push, and Apprise.**
Docs: https://jamcalli.github.io/Pulsarr/
GitHub: https://github.com/jamcalli/Pulsarr
Discord: https://discord.gg/9csTEJn5cR

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Linux / macOS / Windows | Native installer | Standalone binary, no Docker/runtime needed |
| Synology / Linux kernel < 4.11 | Docker (`node` tag) | Use `lakker/pulsarr:node` for older kernels |

---

## Inputs to Collect

### Required
- `TZ` — your timezone (e.g. `America/Los_Angeles`)
- Plex token and server URL (entered via web UI setup)
- Sonarr and/or Radarr URL + API key (configured in UI)

### Optional
- `PUID` / `PGID` — file permission user/group

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  pulsarr:
    image: lakker/pulsarr:latest
    container_name: pulsarr
    ports:
      - "3003:3003"
    volumes:
      - ./data:/app/data
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Los_Angeles
    restart: unless-stopped
```

### Ports
- `3003` — web UI
- `3003/api/docs` — built-in Scalar interactive API docs

### Image tags
- `lakker/pulsarr:latest` — standard (Bun runtime)
- `lakker/pulsarr:node` — Node.js runtime for Synology NAS or kernel < 4.11

### Database
- SQLite by default
- PostgreSQL supported — see configuration docs

### Key features
- Real-time Plex watchlist sync (no extra logins for users)
- Multi-user watchlist support
- Intelligent content routing to Sonarr/Radarr
- Approval workflows with per-user quotas
- Notifications: Discord bot, Plex mobile push, Apprise
- REST API with interactive docs at `/api/docs`

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Early-release project — check release notes before upgrading
- Synology NAS and kernels < 4.11: use the `node` tag to avoid Bun runtime incompatibility
- Full configuration reference: https://jamcalli.github.io/Pulsarr/docs/installation/configuration

---

## References
- Documentation: https://jamcalli.github.io/Pulsarr/
- Quick start: https://jamcalli.github.io/Pulsarr/docs/installation/quick-start
- GitHub: https://github.com/jamcalli/Pulsarr#readme
