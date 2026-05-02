# Emby

**What it is:** A personal media server — organize and stream your movies, TV shows, music, and photos to any device. Features automatic metadata scraping, transcoding, parental controls, Live TV/DVR support, multi-user management, and a polished web/app interface. A freemium alternative to Plex with Emby Premiere for premium features.

> **Freemium / closed source.** Emby Server is free but proprietary. Premium features (hardware transcoding, offline sync, etc.) require Emby Premiere.

**Official URL:** https://emby.media
**Container:** `emby/embyserver`
**License:** Proprietary; free + Emby Premiere subscription
**Stack:** Proprietary; Docker; native `.deb`/`.rpm` packages

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| NAS (Synology, QNAP, etc.) | Native package | Vendor package centers |
| Linux | `.deb` / `.rpm` | Direct native install |
| Windows / macOS | Native installer | GUI installer available |

---

## Inputs to Collect

### Pre-deployment
- `UID` / `GID` — user/group for file permissions (match media file owner)
- `TZ` — timezone
- Media paths — host directories for movies, TV, music
- Config path — persistent Emby data/config directory

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  emby:
    image: emby/embyserver:latest
    container_name: emby
    environment:
      - UID=1000
      - GID=1000
      - TZ=America/New_York
    volumes:
      - /path/to/emby/config:/config
      - /path/to/media:/mnt/media
    ports:
      - "8096:8096"     # HTTP web UI
      - "8920:8920"     # HTTPS (optional)
    restart: unless-stopped
```

**Hardware transcoding (Emby Premiere required):**
```yaml
    devices:
      - /dev/dri:/dev/dri   # Intel Quick Sync / AMD VA-API
```

**Default port:** `8096` (HTTP), `8920` (HTTPS)

**First run:** Visit `http://your-server:8096` to complete the setup wizard — create admin account, add media libraries.

**Upgrade procedure:**
```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **Closed source** — Emby is proprietary; the server code is not auditable or modifiable
- **Emby Premiere for key features** — hardware transcoding, mobile sync, Live TV, Emby Theater, and parental controls for remote users require Emby Premiere (~$4.99/month or $119 lifetime)
- **Transcoding is CPU-intensive** — software transcoding on a VPS may struggle with 4K content; hardware transcoding (Premiere) is recommended for high-resolution streams
- **Emby vs Jellyfin** — Jellyfin is a fully open-source fork of the older Emby codebase and is a popular free alternative

---

## Links
- Website: https://emby.media
- Downloads: https://emby.media/download.html
- Docker Hub: https://hub.docker.com/r/emby/embyserver
- Open-source alternative: https://github.com/jellyfin/jellyfin
