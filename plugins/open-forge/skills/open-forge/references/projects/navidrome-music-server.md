# Navidrome Music Server

Modern, self-hosted music streaming server compatible with the Subsonic API. Navidrome indexes your local music library and streams it to any Subsonic-compatible client (iOS, Android, desktop). Built in Go — fast, lightweight, with low resource usage. Supports multi-user, playlists, smart playlists, scrobbling to Last.fm/ListenBrainz, and a built-in web UI.

**Official site:** https://www.navidrome.org  
**Source:** https://github.com/navidrome/navidrome  
**Upstream docs:** https://www.navidrome.org/docs/installation/  
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended method |
| Any Linux host | Docker CLI | Single container, no compose needed |
| Linux / macOS / Windows | Binary | Pre-built binaries available |
| Raspberry Pi (arm/v6, arm/v7, arm64) | Docker / binary | All ARM variants supported |

---

## Inputs to Collect

| Variable | Description | Example |
|----------|-------------|---------|
| `MUSIC_DIR` | Host path to your music library | `/mnt/media/music` |
| `DATA_DIR` | Host path for Navidrome data/cache/DB | `./navidrome-data` |
| `UID:GID` | User/group ID that owns the music files | `1000:1000` |
| `ND_BASEURL` | Base path if hosting under a subpath | `/music` |

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  navidrome:
    image: deluan/navidrome:latest
    user: 1000:1000  # should match owner of music files
    ports:
      - "4533:4533"
    restart: unless-stopped
    environment:
      # All ND_* variables are optional — defaults shown in comments
      # ND_LOGLEVEL: info
      # ND_SESSIONTIMEOUT: 24h
      # ND_BASEURL: ""
    volumes:
      - ./navidrome-data:/data
      - /path/to/music:/music:ro
```

### Docker CLI
```sh
docker run -d \
  --name navidrome \
  --restart=unless-stopped \
  --user $(id -u):$(id -g) \
  -v /path/to/music:/music:ro \
  -v /path/to/data:/data \
  -p 4533:4533 \
  -e ND_LOGLEVEL=info \
  deluan/navidrome:latest
```

### Data directory
- `/data` — SQLite database, album art cache, session data
- `/music` — read-only mount of your music library; Navidrome scans on startup and watches for changes
- Back up `/data`; the music library itself lives on your host

### Key configuration options (env vars, prefix `ND_`)
| Variable | Description | Default |
|----------|-------------|---------|
| `ND_MUSICFOLDER` | Path inside container to music | `/music` |
| `ND_DATAFOLDER` | Path inside container to data | `/data` |
| `ND_PORT` | HTTP port | `4533` |
| `ND_LOGLEVEL` | Log level (trace/debug/info/warn/error) | `info` |
| `ND_SESSIONTIMEOUT` | Session expiry | `24h` |
| `ND_BASEURL` | URL base path for reverse proxy subpath | `""` |
| `ND_LASTFM_APIKEY` | Last.fm API key for scrobbling | unset |
| `ND_SPOTIFY_ID` | Spotify client ID for artist images | unset |
| `ND_SCANSCHEDULE` | Library rescan schedule (cron format) | `@every 1m` |

Config can also be set in `/data/navidrome.toml` (TOML format) instead of env vars.

### Subsonic clients
Navidrome is Subsonic API-compatible. Supported clients include:
- iOS: substreamer, Amperfy, iSub
- Android: DSub, Ultrasonic, Symfonium
- Desktop: Sublime Music
- Web: built-in Navidrome UI

---

## Upgrade Procedure

1. Pull latest image: `docker compose pull`
2. Restart: `docker compose up -d`
3. DB migrations run automatically
4. Check release notes: https://github.com/navidrome/navidrome/releases

---

## Gotchas

- **User UID:GID must match music file ownership** — if the container user doesn't have read access to `/music`, library scanning silently fails; check file permissions
- **Music folder is read-only mount** — Navidrome never writes to the music directory; metadata is stored in the SQLite DB under `/data`
- **Multi-library support** — available in recent versions; mount additional volumes for each library and configure via `navidrome.toml`
- **Transcoding** — Navidrome can transcode using `ffmpeg` which is included in the Docker image; configure bitrate limits in Settings
- **ARM support** — all ARM variants (v6, v7, arm64) are officially supported; works well on Raspberry Pi

---

## Links
- Upstream README: https://github.com/navidrome/navidrome
- Docker installation: https://www.navidrome.org/docs/installation/docker/
- Configuration options: https://www.navidrome.org/docs/usage/configuration/options/
- Subsonic API compatibility: https://www.navidrome.org/docs/usage/subsonic-api/
