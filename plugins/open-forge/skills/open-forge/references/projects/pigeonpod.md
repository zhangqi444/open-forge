---
name: PigeonPod
description: "Self-hosted YouTube & Bilibili podcast/RSS feed generator with yt-dlp. Docker. Java Spring Boot + SQLite. aizhimou/pigeon-pod. Subscribe channels/playlists, auto-download audio/video, generate private RSS feeds for any podcast app, SponsorBlock, proxy support."
---

# PigeonPod

**Self-hosted YouTube & Bilibili podcast feed generator.** Subscribe to YouTube channels, playlists, or individual videos — PigeonPod downloads audio/video with yt-dlp and serves them as standard RSS feeds to any podcast app. Per-feed keyword/duration filters, retention controls, batch downloads, failed-download email/webhook alerts, Podcasting 2.0 chapters, multilingual UI (8 languages including Chinese).

Built + maintained by **aizhimou**. See repo license.

- Upstream repo: <https://github.com/aizhimou/pigeon-pod>
- GHCR: `ghcr.io/aizhimou/pigeon-pod`
- SaaS: <https://pigeonpod.cloud> (cloud hosted option)

## Architecture in one minute

- **Java Spring Boot** backend + frontend
- **SQLite** database
- yt-dlp for downloads (managed in-app; update without container restart)
- Port **8834** → container **8080**
- Media stored in data volume
- Resource: **medium** — JVM; plan for 512 MB+ RAM

## Compatible install methods

| Infra      | Runtime                      | Notes                                            |
| ---------- | ---------------------------- | ------------------------------------------------ |
| **Docker** | `ghcr.io/aizhimou/pigeon-pod` | **Primary** — from GHCR; see compose in README   |

## Install via Docker Compose

```yaml
services:
  pigeon-pod:
    image: ghcr.io/aizhimou/pigeon-pod:latest
    restart: unless-stopped
    container_name: pigeon-pod
    ports:
      - "8834:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:sqlite:/data/pigeon-pod.db
      # - PIGEON_AUTH_ENABLED=false  # only if behind a trusted auth proxy
    volumes:
      - data:/data

volumes:
  data:
```

```bash
docker compose up -d
```

Visit `http://localhost:8834`.

## Inputs to collect

| Input | Notes |
|-------|-------|
| `SPRING_DATASOURCE_URL` | SQLite path (default: `/data/pigeon-pod.db`) |
| `PIGEON_AUTH_ENABLED` | Set `false` only if behind a trusted auth proxy |
| YouTube API key (optional) | For YouTube quota monitoring |
| Cookies (optional) | YouTube/Bilibili cookies for restricted content |
| Proxy URL (optional) | Route yt-dlp traffic through a proxy |

## Features overview

| Feature | Details |
|---------|---------|
| Channel subscriptions | Subscribe to YouTube or Bilibili channels |
| Playlist subscriptions | Subscribe to any playlist |
| Single-video feeds | Turn one YouTube video into an auto-playlist RSS |
| RSS feed generation | Standard RSS 2.0; protected with per-feed auth |
| Auto-sync | Cron-based sync; configurable interval |
| History backfill | Backfill older videos on demand |
| Audio/video output | Download as audio (MP3/M4A) or video; quality + format control |
| SponsorBlock | Skip sponsored segments (for compatible episodes) |
| Per-feed filters | Keyword, duration, episode count limits |
| Batch downloads | Queue large back-catalogs efficiently |
| Download dashboard | Task status; retry/cancel/delete in bulk |
| Failed-download alerts | Email or webhook digest when retries exhausted |
| Cookie support | YouTube + Bilibili cookies for restricted/member content |
| Proxy support | Route YouTube API + yt-dlp through an HTTP proxy |
| In-app yt-dlp management | Switch versions, update without container restart |
| Custom yt-dlp args | Fine-tune downloads with arbitrary yt-dlp arguments |
| Podcasting 2.0 chapters | Generate chapter files for richer podcast navigation |
| One-click sharing | Public episode page for sharing without login |
| OPML export | Export subscriptions for migration to other podcast clients |
| YouTube API quota monitoring | Dashboard showing API quota usage before hitting limits |
| Auto-login (trusted env) | Skip manual sign-in when behind a trusted auth proxy |
| Multilingual UI | 8 languages: English, Chinese, Spanish, French, German, Portuguese, Japanese, Korean |

## Podcast app integration

Once PigeonPod is running, copy a feed's RSS URL and add it to any podcast app:

- **Pocket Casts**, **Overcast**, **AntennaPod**, **Podbean**, **Castro** — paste RSS URL → subscribe
- **Plex** / **Jellyfin** — use as a remote podcast feed source
- Feeds are password-protected; provide credentials in the podcast app when prompted

## Gotchas

- **`PIGEON_AUTH_ENABLED` defaults to `true`.** Do NOT set it to `false` unless PigeonPod is behind a trusted reverse proxy with its own authentication (e.g., Authelia, Authentik, Cloudflare Access). Disabling auth exposes your feeds and download controls to anyone.
- **YouTube API quota.** YouTube's Data API has a daily quota limit. PigeonPod includes a quota monitoring dashboard. For high-volume use (many channels, frequent syncs), consider the YouTube API quota dashboard carefully.
- **yt-dlp updates are critical.** YouTube frequently changes its internal API. yt-dlp must stay up-to-date to keep downloads working. PigeonPod supports in-app yt-dlp version management — update yt-dlp from the Settings page without restarting the container.
- **Cookies for restricted content.** For age-restricted videos, member content, or Bilibili premium content, export your browser cookies (YouTube, Bilibili) and upload them in PigeonPod settings.
- **JVM startup time.** The Java Spring Boot backend takes 15–30 seconds to start on first launch. The container is healthy when the port responds.
- **Storage grows over time.** Downloaded media accumulates in the data volume. Configure per-feed retention limits (episode count) to auto-prune old downloads. Monitor disk usage.

## Backup

```sh
docker compose stop pigeon-pod
sudo tar czf pigeonpod-$(date +%F).tgz ./data/
docker compose start pigeon-pod
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Java Spring Boot development, yt-dlp integration, multilingual UI, SaaS cloud option. See repo license.

## YouTube-downloader-family comparison

- **PigeonPod** — Java, YouTube+Bilibili, RSS feeds for podcast apps, filters, alerts, chapters
- **Youtarr** — Node.js, YouTube channels, NFO/poster metadata for Plex/Jellyfin
- **Tubesync** — Python, YouTube+SoundCloud, Plex/Jellyfin folders
- **TubeArchivist** — Python, YouTube archiver, dedicated web UI, Elasticsearch
- **yt-dlp** — CLI; the underlying download engine all of the above use

**Choose PigeonPod if:** you want to turn YouTube/Bilibili channels into standard RSS podcast feeds for any podcast app, with per-feed filters, batch downloads, failed-download alerts, and in-app yt-dlp management.

## Links

- Repo: <https://github.com/aizhimou/pigeon-pod>
- GHCR: `ghcr.io/aizhimou/pigeon-pod`
