# Plex Prerolls

**What it is:** A script/service that automates management of Plex pre-roll videos — the short clips that play before movies start. Define schedules (date ranges, weekly, monthly, always-on) so different prerolls play during holidays, seasons, or specific events. Supports path globbing for randomized selection, webhook ingestion for Plex events, and auto-generation of preroll videos.

**Official URL:** https://codeberg.org/nwithan8/plex-prerolls
**Container:** `nwithan8/plex_prerolls:latest`
**License:** GPL-3.0
**Stack:** Python; Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux / homelab | Docker Compose | Recommended |
| Any Linux / homelab | Docker CLI | Run directly |

---

## Inputs to Collect

### Pre-deployment (volumes + environment)
- `/path/to/config` → `/config` — directory containing `config.yaml`
- `/path/to/logs` → `/logs` — log output directory
- `/path/to/prerolls` → `/files` — root directory of preroll video files (for path globbing)
- `/path/to/auto-generated/renders` → `/renders` — temp dir for auto-generated preroll rendering
- `/path/to/auto-generated/parent` → `/auto_rolls` — output dir for auto-generated prerolls
- `TZ` — timezone for cron schedule (e.g. `America/New_York`)
- `PUID` / `PGID` — UID/GID to run as

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  plex_prerolls:
    image: nwithan8/plex_prerolls:latest
    volumes:
      - /path/to/config:/config
      - /path/to/logs:/logs
      - /path/to/prerolls:/files
      - /path/to/auto-generated/renders:/renders
      - /path/to/auto-generated/parent:/auto_rolls
    ports:
      - "8283:8283"
    environment:
      TZ: America/New_York
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8283/last-run-within?timeframe=24h"]
      interval: 5m
      timeout: 10s
      retries: 3
```

**`config.yaml` structure** — defines Plex connection and schedule rules:
```yaml
plex:
  url: http://your-plex-server:32400
  token: YOUR_PLEX_TOKEN

prerolls:
  always:
    - path: /files/always/*.mp4
      count: 1   # randomly pick 1 from the glob

  date_range:
    - name: Christmas
      start_date: "12-01"
      end_date: "12-26"
      paths:
        - /files/christmas/*.mp4

  monthly:
    - month: 10   # October
      paths:
        - /files/halloween/*.mp4
```

**Port `8283`** — webhook endpoint and health check API.

**Schedule types:**
- `always` — always appended; use `count` for random subset
- `date_range` — active between two dates (supports wildcards for year-agnostic ranges)
- `weekly` — active during a specific week of the year
- `monthly` — active during a specific month

**Plex token retrieval:**
1. Open Plex in browser → DevTools → Network tab → reload
2. Find any request to `plex.tv` → look for `X-Plex-Token` in headers/URL

**Upgrade procedure:**
```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **Run as Docker container only** — direct Python script execution is no longer advised (webhook ingestion requires the server component)
- **Plex token required** — find it via browser DevTools as described above
- **Preroll paths in `config.yaml` are container paths** — use `/files/...` (the container mount), not host paths
- **Auto-generation feature** — the `/renders` and `/auto_rolls` volumes are only needed if using auto-generated prerolls; optional for basic use

---

## Links
- Codeberg: https://codeberg.org/nwithan8/plex-prerolls
- Docker Hub: https://hub.docker.com/r/nwithan8/plex_prerolls
