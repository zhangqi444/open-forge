# Posteria

**What it is:** A web-based media poster management system for organizing and storing custom artwork for movies, TV shows, seasons, and collections. Integrates with Plex for auto-import and real-time poster updates, with TMDB/TVDB/Fanart.tv lookup built in.

**Official URL:** https://github.com/jeremehancock/Posteria
**Docker Hub:** `bozodev/posteria`
**License:** MIT
**Stack:** PHP; Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| Unraid | Community App Store | Available as Unraid CA app |
| Homelab | Docker Compose | Lightweight; low resource use |

---

## Inputs to Collect

### Pre-deployment
- `AUTH_USERNAME` / `AUTH_PASSWORD` — web UI login credentials (change from defaults!)
- `PLEX_SERVER_URL` — your Plex server URL (optional; required for Plex import/sync)
- `PLEX_TOKEN` — Plex authentication token (optional)
- `PUID` / `PGID` — host user/group IDs for correct file permissions
- `TZ` — timezone

### Runtime
- TMDB/TVDB/Fanart.tv API keys — configured in app settings for poster lookup
- `EXCLUDED_LIBRARIES` — comma-separated Plex library names to skip during import
- Auto-import schedule (24h, 12h, 6h, 3h, 1h) if enabled

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  posteria:
    image: bozodev/posteria:latest
    container_name: posteria
    ports:
      - "1818:80"
    environment:
      - AUTH_USERNAME=admin       # Change this!
      - AUTH_PASSWORD=changeme    # Change this!
      - SESSION_DURATION=3600
      - AUTH_BYPASS=false
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - PLEX_SERVER_URL=
      - PLEX_TOKEN=
      - AUTO_IMPORT_ENABLED=false
      - AUTO_IMPORT_SCHEDULE=1h
    volumes:
      - ./posters:/config/posters
      - ./data:/config/data
    restart: unless-stopped
```

**Default port:** `1818`

**Data volumes:**
- `./posters` → `/config/posters` — poster image files
- `./data` → `/config/data` — database and logs

**PWA:** Installable as a Progressive Web App from any supported browser.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **`AUTH_BYPASS=true` is dangerous** — only use on fully private networks; never expose to the internet with bypass enabled
- **Plex integration is optional** — works as a standalone poster manager without Plex
- **Auto-import requires Plex credentials** — `PLEX_SERVER_URL` and `PLEX_TOKEN` must be set
- **Plex poster updates are automatic** when `PLEX_REMOVE_OVERLAY_LABEL=true` — set this for Kometa/PMM compatibility
- **Orphan detection** scans for posters no longer associated with any library item — run periodically to clean up storage
- Supports JPG, JPEG, PNG, WebP formats; max file size configurable via `MAX_FILE_SIZE` (bytes)

---

## Links
- GitHub: https://github.com/jeremehancock/Posteria
- Docker Hub: https://hub.docker.com/r/bozodev/posteria
