# MediaLyze

A self-hosted media library analysis tool for large video collections. Scans your library directories using ffprobe and presents rich technical metadata through a FastAPI + React web UI: codecs, streams, subtitles, quality scores, format normalisation, show/season recognition, and historical analysis charts. Read-only access to your files — no playback, scraping, or modification. Single-container Docker deployment with SQLite. Also available as native desktop apps (Windows, macOS, Linux via Electron).

- **GitHub:** https://github.com/frederikemmer/MediaLyze
- **Docker image:** `ghcr.io/frederikemmer/medialyze:latest`
- **License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Single container; media dirs bind-mounted read-only |
| Any Docker host | docker run | Same single-container model |
| Windows / macOS / Linux | Desktop app | Electron app from GitHub Releases; no Docker needed |

---

## Inputs to Collect

### Deploy Phase (environment variables)
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| TZ | No | UTC | Timezone (e.g. Europe/Berlin, America/New_York) |

No authentication variables in the current release — bring your own auth (reverse proxy with basic auth, Authelia, etc.) for internet-facing deployments.

### Media Mounts
Map your media directories into the container at /media (or /media/<name> for multiple libraries):
```yaml
volumes:
  - /path/to/your/media:/media:ro
  - /path/to/another/library:/media/movies:ro
```

---

## Software-Layer Concerns

### Config
- All config via environment variables and volume mounts
- Library paths configured in the web UI after first launch (Settings → Libraries)
- Ignore patterns configured in the UI (glob syntax, e.g. *.nfo, */Extras/*)

### Data Directories
| Mount | Purpose |
|-------|---------|
| ./config:/config | SQLite database + application config (persist this) |
| /your/media:/media:ro | Media library (read-only) |

### Ports
- 8080 — Web UI

---

## Minimal docker-compose.yml

```yaml
services:
  medialyze:
    image: ghcr.io/frederikemmer/medialyze:latest
    container_name: medialyze
    ports:
      - "8080:8080"
    environment:
      TZ: UTC
    volumes:
      - ./config:/config
      - /path/to/your/media:/media:ro
    restart: unless-stopped
```

---

## Upgrade Procedure

```bash
docker compose pull medialyze
docker compose up -d medialyze
```

SQLite schema migrations run automatically on startup. Check GitHub releases for breaking changes.

---

## Gotchas

- **No built-in auth:** MediaLyze has no login page in the current release; put it behind a reverse proxy with authentication before exposing to a network
- **ffprobe is required (included in Docker image):** ffprobe must be available in the container; the official Docker image includes it — bare-metal users must install ffmpeg/ffprobe separately
- **Read-only mounts recommended:** Mount media with :ro to ensure MediaLyze cannot accidentally modify your files
- **Config volume must be persisted:** The SQLite database (scan history, library config, analysis results) is stored in /config — losing this volume means losing all scan history
- **Initial scan can be slow:** Large libraries take time on the first full scan; subsequent scans are incremental (path + size + mtime comparison)
- **Desktop app alternative:** If you don't want Docker, download the Electron desktop app from GitHub Releases (Windows .exe, macOS .dmg, Linux .AppImage)

---

## References
- GitHub: https://github.com/frederikemmer/MediaLyze
- docker-compose.yml: https://github.com/frederikemmer/MediaLyze/blob/HEAD/docker/docker-compose.yaml
- Desktop downloads: https://github.com/frederikemmer/MediaLyze/releases/latest
