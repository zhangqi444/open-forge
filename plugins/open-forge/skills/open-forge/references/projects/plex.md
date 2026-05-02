# Plex

**What it is:** The leading self-hosted media server platform. Organize and stream your personal collection of movies, TV shows, music, and photos to any device — phones, smart TVs, browsers, game consoles. Features automatic metadata scraping, transcoding, Plex Pass extras (live TV, offline sync, hardware transcoding), and multi-user support.

> **Freemium / closed source.** Plex Media Server is free but proprietary. Some features require Plex Pass (subscription).

**Official URL:** https://www.plex.tv
**License:** Proprietary; free tier + Plex Pass subscription for premium features
**Stack:** Proprietary; Docker image `plexinc/pms-docker`; native packages for Linux/Windows/macOS/NAS

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; official image |
| NAS (Synology, QNAP, etc.) | Native package | Direct Plex app from vendor package center |
| Linux | `.deb` / `.rpm` | Direct native install |
| DigitalOcean / Linode | Docker | Standard VPS deployment |

---

## Inputs to Collect

### Pre-deployment
- `PLEX_CLAIM` — one-time claim token from https://plex.tv/claim (valid 4 minutes); links server to your Plex account
- `PUID` / `PGID` — UID/GID for file permissions (should match owner of media files)
- `TZ` — timezone (e.g. `America/New_York`)
- Media paths — host directories for movies, TV shows, music

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  plex:
    image: plexinc/pms-docker:latest
    container_name: plex
    network_mode: host   # required for local network discovery
    environment:
      - PLEX_CLAIM=claim-xxxxxxxxxxxxxxxxxxxx
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - /path/to/plex/config:/config
      - /path/to/plex/transcode:/transcode
      - /path/to/media:/data
    restart: unless-stopped
```

**`network_mode: host`** — strongly recommended for local network discovery (GDM). Without it, Plex may not be discoverable on your LAN. Port `32400` is the default web UI port.

**Web UI:** http://your-server:32400/web (or via app.plex.tv)

**First run:** Visit the web UI and sign in with your Plex account to claim the server and add libraries.

**Transcode directory:** Use a fast disk or a `tmpfs` mount for `/transcode` to avoid wearing out storage during active transcoding.

**Hardware transcoding (Plex Pass required):** Add device to compose:
```yaml
devices:
  - /dev/dri:/dev/dri   # Intel Quick Sync / AMD
```

**Upgrade procedure:**
```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **`PLEX_CLAIM` expires in 4 minutes** — generate it immediately before `docker compose up` at https://plex.tv/claim
- **`network_mode: host`** — required for LAN discovery; incompatible with Docker port mappings (remove `ports:` if using host networking)
- **Closed source** — Plex is proprietary; you cannot audit or modify the server code
- **Plex Pass for key features** — hardware transcoding, offline sync, live TV DVR, and multi-user home all require Plex Pass (~$5/month or $120 lifetime)
- **Remote access requires Plex account** — streaming outside LAN requires a plex.tv account and internet connectivity to Plex's relay infrastructure (or manual port forwarding)

---

## Links
- Website: https://www.plex.tv
- Docker image: https://hub.docker.com/r/plexinc/pms-docker
- Claim token: https://plex.tv/claim
- Downloads (native): https://www.plex.tv/media-server-downloads/
