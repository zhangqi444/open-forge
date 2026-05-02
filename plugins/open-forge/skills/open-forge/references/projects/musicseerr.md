---
name: musicseerr-project
description: MusicSeerr recipe for open-forge. Self-hosted music request and discovery app built around Lidarr. Search MusicBrainz, request albums, stream from Jellyfin/Navidrome/Plex/local files/YouTube, scrobble to ListenBrainz/Last.fm, AI discovery. Single Docker container. Upstream: https://github.com/HabiRabbu/Musicseerr
---

# MusicSeerr

A self-hosted music request and discovery app built around [Lidarr](https://lidarr.audio/). Search the full MusicBrainz catalogue, request albums for Lidarr to download, stream music from Jellyfin/Navidrome/Plex/local files/YouTube, and discover new music based on your listening history. Scrobbles to ListenBrainz and Last.fm simultaneously.

Upstream: <https://github.com/HabiRabbu/Musicseerr> | Docs: <https://musicseerr.com>

Single Docker container. All configuration via the web UI after first run.

## Compatible combos

| Infra | Streaming source | Notes |
|---|---|---|
| Any host with Lidarr | Navidrome (Subsonic API) | Primary self-hosted music stack |
| Any host with Lidarr | Jellyfin | Direct-play streaming, Jellyfin scrobbling |
| Any host with Lidarr | Plex | Direct-play, multi-library, native Plex scrobbling |
| Any host with Lidarr | Local files | Mount music directory into container |
| Any host with Lidarr | YouTube | Stream/preview albums not yet downloaded |

**Lidarr is the only required dependency.** Streaming sources are optional and configured after first run.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port for MusicSeerr?" | Default: `8688` |
| preflight | "PUID / PGID?" | Run `id` on the host; default `1000:1000` |
| preflight | "Timezone?" | `TZ` env var; e.g. `Europe/London`, `America/New_York` |
| preflight (local music) | "Path to music library on host?" | Mount as `/music:ro`; must match Lidarr's root folder path |
| config (post-start) | "Lidarr URL and API key?" | Configured in MusicSeerr Settings after first run |
| config (post-start) | "Streaming service connections?" | Jellyfin/Navidrome/Plex — all configured in Settings |
| config (post-start) | "ListenBrainz / Last.fm API keys?" | Configured in Settings for scrobbling |

## Software-layer concerns

### Image

```
ghcr.io/habirabbu/musicseerr:latest
```

Also available on Docker Hub: `habirabbu/musicseerr:latest`

### Compose

```yaml
services:
  musicseerr:
    image: ghcr.io/habirabbu/musicseerr:latest
    container_name: musicseerr
    restart: unless-stopped
    environment:
      - PUID=1000      # match host user (run `id` to find)
      - PGID=1000
      - PORT=8688
      - TZ=Etc/UTC     # e.g. Europe/London, America/New_York
    ports:
      - "8688:8688"
    volumes:
      - ./config:/app/config    # Persistent app configuration
      - ./cache:/app/cache      # Cover art and metadata cache
      # Optional: mount music library for local file playback
      # Left side must match Lidarr's root folder path
      # Right side (/music) must match "Music Directory Path" in Settings > Local Files
      # - /path/to/music:/music:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8688/health"]
      interval: 30s
      timeout: 10s
      start_period: 15s
      retries: 3
```

> Source: upstream README — <https://github.com/HabiRabbu/Musicseerr>

### Post-start configuration

Open `http://localhost:8688` and go to **Settings** to configure:
1. **Lidarr** — URL (e.g. `http://lidarr:8686`) and API key (required)
2. **Streaming sources** — Jellyfin, Navidrome, Plex (all optional)
3. **Scrobbling** — ListenBrainz and/or Last.fm API keys (optional)
4. **Local files** — music directory path (must match the container mount `/music`)

### Recommended Lidarr companion stack

| Service | Role |
|---|---|
| [Lidarr](https://lidarr.audio/) (nightly recommended) | Library management and download orchestration |
| [slskd](https://github.com/slskd/slskd) | Soulseek download client |
| [Tubifarry](https://github.com/Tubifarry/Tubifarry) | YouTube-based download client for Lidarr |

slskd and Tubifarry are optional — together they cover most music sourcing needs.

### Local file playback

Mount your music library into the container:

```yaml
volumes:
  - /path/to/music:/music:ro
```

The left-hand path **must match Lidarr's root folder path** exactly (so MusicSeerr can resolve tracks). Set "Music Directory Path" to `/music` in MusicSeerr Settings → Local Files.

### Features summary

- **Request** — search MusicBrainz catalogue; request album → Lidarr downloads it
- **Stream** — built-in player with Jellyfin/Navidrome/Plex/local/YouTube per-track sources; queue, shuffle, seek, volume, 10-band EQ
- **Discover** — home page trending + "Because You Listened To" carousels; discover queue with similar artists, library gaps, fresh releases, global charts
- **Library** — browse by artist/album across all connected sources; statistics view
- **Scrobble** — ListenBrainz + Last.fm simultaneously; now-playing updates on track start
- **Playlists** — cross-source playlists (Jellyfin + Navidrome + local + YouTube tracks in one list)
- **Profile** — display name, avatar, connected services, library stats

### Navidrome (Subsonic API) connection

In Settings → Navidrome:
- URL: e.g. `http://navidrome:4533`
- Username / password (Navidrome credentials)

### Jellyfin connection

In Settings → Jellyfin:
- Server URL, username, password
- Codec and bitrate preferences
- Scrobbling back to Jellyfin is automatic for Jellyfin-sourced playback

### Plex connection

In Settings → Plex:
- Plex token
- Multi-library selection supported
- Direct-play audio only; native Plex scrobbling included

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Config and cache in `./config` and `./cache` persist across upgrades.

## Gotchas

- **Lidarr is required** — MusicSeerr is a front-end for Lidarr. Without Lidarr (and its API key), the app won't function.
- **Local file mount path must match Lidarr's root folder** — if the host paths differ between Lidarr and MusicSeerr, track resolution fails silently.
- **`/music` container path is fixed** — only the host-side of the local files mount is configurable; `/music` inside the container is the expected path (set in Settings → Local Files).
- **All streaming sources are optional** — configure only the ones you actually use. MusicSeerr works with just Lidarr.
- **PUID/PGID affect file access** — set them to match the host user that owns the config/cache directories to avoid permission errors on startup.
- **Lidarr nightly recommended** — upstream README suggests the nightly build of Lidarr for best compatibility with MusicSeerr.
- **YouTube playback requires no credentials** — YouTube sources are auto-linked or set manually; no API key needed for preview streaming.
- **Cache directory grows over time** — `./cache` stores cover art and metadata; periodically review its size.

## Links

- Upstream README: <https://github.com/HabiRabbu/Musicseerr>
- Documentation: <https://musicseerr.com>
- GHCR image: <https://github.com/habirabbu/musicseerr/pkgs/container/musicseerr>
- Docker Hub: <https://hub.docker.com/r/habirabbu/musicseerr>
- Discord: <https://discord.gg/B5suDg7gu2>
