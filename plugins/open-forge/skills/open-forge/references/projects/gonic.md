---
name: gonic
description: gonic recipe for open-forge. Lightweight Subsonic-compatible music streaming server — browse by folder or tags, transcoding, scrobbling, podcasts, multi-user. Docker install. Upstream: https://github.com/sentriz/gonic
---

# gonic

Lightweight, Subsonic-compatible music streaming server. Stream your music collection to any Subsonic-compatible client — browse by folder or tags, on-the-fly transcoding, last.fm/ListenBrainz scrobbling, podcasts, and jukebox mode.

2,373 stars · GPL-3.0

Upstream: https://github.com/sentriz/gonic
Docker Hub: https://hub.docker.com/r/sentriz/gonic

## What it is

gonic provides a self-hosted music streaming server with Subsonic API compatibility:

- **Subsonic API** — Works with all Subsonic/Airsonic clients (DSub, Ultrasonic, Symfonium, Strawberry, Amperfy, and more)
- **Browse by folder** — Preserves your full directory tree
- **Browse by tags** — Uses taglib for metadata (mp3, FLAC, opus, m4a, wav, ape, etc.)
- **On-the-fly transcoding** — Convert to lower bitrate/format via ffmpeg; results cached
- **Multiple music paths** — Support multiple root directories, optionally with aliases
- **Multi-user** — Each user has separate transcoding prefs, playlists, ratings
- **Playlists** — M3U playlist support with per-user directories
- **Scrobbling** — Last.fm and ListenBrainz
- **Artist info** — Biographies and similar artists from Last.fm API
- **Podcasts** — Podcast management and playback
- **Jukebox mode** — Gapless server-side playback via mpv (no client streaming)
- **Watcher** — Optionally watch filesystem for new music and auto-rescan
- **Fast scanning** — ~50k tracks initial scan ~10 min; incremental ~6s
- **Web UI** — Configuration, scan management, user admin
- **ARM support** — Works on Raspberry Pi and other ARM devices

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | Single container | Recommended; sentriz/gonic image |
| Docker Compose | With reverse proxy | Add Nginx/Traefik for HTTPS |
| Bare metal | Go binary | Lightweight, good for Pi |
| Package manager | Various | See repology.org/project/gonic |

## Inputs to collect

### Phase 1 — Pre-install
- Music library path(s)
- Cache directory path (for transcodes and covers)
- Port to expose (default: 4747)
- Last.fm API key and secret (optional, for artist info and scrobbling)

## Software-layer concerns

### Key environment variables
  GONIC_MUSIC_PATH=/music                # required; comma-separated for multiple paths
  GONIC_PODCAST_PATH=/podcasts           # optional
  GONIC_PLAYLISTS_PATH=/playlists        # optional
  GONIC_CACHE_PATH=/cache                # required; for transcodes, covers
  GONIC_DB_PATH=/data/gonic.db           # optional; defaults to data dir
  GONIC_LISTEN_ADDR=0.0.0.0:4747        # default
  GONIC_SCAN_INTERVAL=60                 # minutes; 0 = manual only
  GONIC_SCAN_AT_START_ENABLED=true
  GONIC_SCAN_WATCHER_ENABLED=false       # watch filesystem for changes
  GONIC_TRANSCODE_CACHE_SIZE=0           # MB; 0 = no limit

### Multi-folder support
  GONIC_MUSIC_PATH=/path/to/albums,/path/to/compilations
  # With aliases:
  GONIC_MUSIC_PATH=Albums->/path/to/albums,Compilations->/path/to/compilations

### Ports
- 4747 — HTTP (default)
- Configure TLS via GONIC_TLS_CERT and GONIC_TLS_KEY, or use reverse proxy

### First login
Default credentials: admin / admin
Change password immediately via web UI at http://<host>:4747

## Docker Compose install

  version: '3'
  services:
    gonic:
      image: sentriz/gonic:latest
      container_name: gonic
      restart: unless-stopped
      ports:
        - "4747:4747"
      environment:
        - GONIC_MUSIC_PATH=/music
        - GONIC_PODCAST_PATH=/podcasts
        - GONIC_PLAYLISTS_PATH=/playlists
        - GONIC_CACHE_PATH=/cache
        - GONIC_DB_PATH=/data/gonic.db
        - GONIC_SCAN_INTERVAL=60
        - GONIC_SCAN_AT_START_ENABLED=true
      volumes:
        - /path/to/music:/music:ro
        - /path/to/podcasts:/podcasts
        - /path/to/playlists:/playlists
        - gonic_cache:/cache
        - gonic_data:/data

  volumes:
    gonic_cache:
    gonic_data:

### Transcoding (requires ffmpeg)
ffmpeg is included in the Docker image. Clients request transcoding via Subsonic API.
Configure quality per-user in web UI: Admin > Users > edit user > Transcoding.

### Reverse proxy (Nginx)
  server {
    listen 443 ssl;
    server_name music.example.com;
    location / {
      proxy_pass http://localhost:4747;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }
  }

## Upgrade procedure

1. Pull latest: docker pull sentriz/gonic:latest
2. Restart: docker compose up -d --force-recreate gonic
3. Database migrations apply automatically on startup
4. Verify library scan and client connectivity

## Gotchas

- Default admin/admin — change immediately after first login
- Read-only music mount — use :ro on music volume to prevent accidental writes
- ffmpeg required for transcoding — included in Docker image; bare-metal installs need ffmpeg in PATH
- Subsonic API only — no web player built-in; needs a Subsonic client (Symfonium, DSub, Strawberry, etc.)
- Tag-based browsing requires proper tags — files without ID3/FLAC tags won't appear correctly in tag mode; use folder mode as fallback
- GONIC_SCAN_WATCHER_ENABLED — filesystem watching can be resource-intensive for large libraries; prefer scheduled scans for NAS/remote mounts
- Jukebox mode needs mpv — server-side playback via jukebox requires mpv installed on the server

## Links

- Upstream README: https://github.com/sentriz/gonic/blob/master/README.md
- Installation wiki: https://github.com/sentriz/gonic/wiki/installation
- Configuration options: https://github.com/sentriz/gonic#configuration-options
- Subsonic clients: https://github.com/sentriz/gonic?tab=readme-ov-file#features (client list)
- Docker Hub: https://hub.docker.com/r/sentriz/gonic
