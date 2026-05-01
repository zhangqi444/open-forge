---
name: Ganymede
description: "Self-hosted Twitch VOD and live stream archiving platform with real-time chat playback. Docker. Go + PostgreSQL + Next.js. Zibbp/ganymede. Watched channels, automatic archiving, chat rendering, SSO/OAuth, playlists, webhook notifications. GPL-3.0."
---

# Ganymede

**Self-hosted Twitch VOD and live stream archiving.** Ganymede archives Twitch VODs and live streams with synchronized, rendered chat playback. Files are saved in a simple, archival-friendly structure that works without Ganymede. Watch channels automatically, filter what gets archived, render chat for offline viewing, and manage your archive through a clean web UI.

Built + maintained by **Zibbp**. Successor to Ceres. GPL-3.0.

- Upstream repo: <https://github.com/Zibbp/ganymede>
- Docker: `ghcr.io/zibbp/ganymede`
- Wiki: <https://github.com/Zibbp/ganymede/wiki>

## Architecture in one minute

- **Go** backend API
- **Next.js** frontend (served by the same container)
- **PostgreSQL** — all data (VODs, channels, queue, users)
- Port **4800** → container port 4000
- Large **video storage volume** required (50 GB+ recommended)
- Requires a **Twitch application** (Client ID + Secret)
- Resource: **medium-high** — FFmpeg for video/chat rendering; storage-heavy

## Compatible install methods

| Infra      | Runtime                     | Notes                                           |
| ---------- | --------------------------- | ----------------------------------------------- |
| **Docker** | `ghcr.io/zibbp/ganymede`    | **Primary** — single app container + Postgres   |

## Install via Docker

```yaml
services:
  ganymede:
    container_name: ganymede
    image: ghcr.io/zibbp/ganymede:latest
    restart: unless-stopped
    depends_on:
      - ganymede-db
    environment:
      - TZ=America/Chicago          # Set to your timezone
      - VIDEOS_DIR=/data/videos
      - TEMP_DIR=/data/temp
      - LOGS_DIR=/data/logs
      - CONFIG_DIR=/data/config
      - DB_HOST=ganymede-db
      - DB_PORT=5432
      - DB_USER=ganymede
      - DB_PASS=changeme
      - DB_NAME=ganymede-prd
      - DB_SSL=disable
      - TWITCH_CLIENT_ID=           # from your Twitch application
      - TWITCH_CLIENT_SECRET=       # from your Twitch application
      # Worker concurrency
      - MAX_CHAT_DOWNLOAD_EXECUTIONS=3
      - MAX_CHAT_RENDER_EXECUTIONS=2
      - MAX_VIDEO_DOWNLOAD_EXECUTIONS=2
      - MAX_VIDEO_CONVERT_EXECUTIONS=3
      - MAX_VIDEO_SPRITE_THUMBNAIL_EXECUTIONS=2
      # Auth
      - REQUIRE_LOGIN=false
      - SHOW_SSO_LOGIN_BUTTON=true
      - FORCE_SSO_AUTH=false
      # OAuth (optional)
      # - OAUTH_ENABLED=false
      # - OAUTH_PROVIDER_URL=
      # - OAUTH_CLIENT_ID=
      # - OAUTH_CLIENT_SECRET=
      # - OAUTH_REDIRECT_URL=http://IP:PORT/api/v1/auth/oauth/callback
    volumes:
      - /path/to/vod/storage:/data/videos
      - ./temp:/data/temp
      - ./logs:/data/logs
      - ./config:/data/config
    ports:
      - "4800:4000"
    healthcheck:
      test: curl --fail http://localhost:4000/health || exit 1
      interval: 60s
      retries: 5
      start_period: 60s
      timeout: 10s

  ganymede-db:
    container_name: ganymede-db
    image: postgres:14
    volumes:
      - ./ganymede-db:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=changeme
      - POSTGRES_USER=ganymede
      - POSTGRES_DB=ganymede-prd
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ganymede -d ganymede-prd"]
      interval: 30s
      timeout: 60s
      retries: 5
      start_period: 60s
```

```bash
docker compose up -d
```

Visit `http://localhost:4800` → login with `admin` / `ganymede` → **change the password immediately**.

## Twitch application setup

1. Go to <https://dev.twitch.tv/console/apps/create>
2. Create a new application (name it anything, set redirect URL to your instance)
3. Copy the **Client ID** and **Client Secret** into `TWITCH_CLIENT_ID` / `TWITCH_CLIENT_SECRET`

## Features overview

| Feature | Details |
|---------|---------|
| VOD archiving | Download and archive Twitch VODs (past broadcasts, highlights, clips) |
| Live stream archiving | Archive streams as they happen |
| Chat playback | Synchronized real-time chat replay alongside video |
| Chat rendering | Renders chat to a standalone video file for offline archival |
| Watched channels | Auto-archive new VODs and/or live streams from specified channels |
| Advanced channel filters | Filter by title, game, duration, and more |
| Playlists | Organise VODs into playlists |
| Progress saving | Resume playback from where you left off |
| Queue system | Recoverable task queue for downloads and processing |
| Worker concurrency | Configure parallel download/render/convert jobs |
| Custom FFmpeg params | Post-download FFmpeg processing per VOD |
| Custom chat render params | Fine-tune chat rendering output |
| Webhook notifications | Notify on archive events |
| SSO / OAuth | OpenID Connect authentication |
| Light/dark mode | UI theme toggle |
| API | Full REST API for integrations |
| Archival-friendly files | Files stored in a format that works without Ganymede |
| Translations | Multi-language UI support |

## Storage requirements

Plan for large volumes. See the [storage requirements wiki](https://github.com/Zibbp/ganymede/wiki/Storage-Requirements). A single stream at 1080p60 can be several gigabytes. Recommendations: 50 GB minimum, network-attached storage for large archives.

## Gotchas

- **Twitch application required.** You must create a Twitch Developer application and provide Client ID + Secret. Without this, Ganymede cannot access the Twitch API.
- **Default credentials are public.** The default login is `admin` / `ganymede` — change it immediately after first login, or create a new admin user and delete the default.
- **FFmpeg is included.** The Docker image bundles FFmpeg for video/chat processing — no separate installation needed.
- **VOD availability window.** Twitch VODs expire (typically 14–60 days depending on account type). Archive soon after broadcast or use watched channels for automatic capture.
- **Storage grows fast.** High-quality streams are large. Monitor disk space and plan accordingly.
- **GPL-3.0 license.** Modifications must be released under GPL-3.0.

## Backup

```sh
# Database
docker compose exec ganymede-db pg_dump -U ganymede ganymede-prd > ganymede-$(date +%F).sql
# Videos are self-contained in your storage volume — back up the volume separately
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Go/Next.js development, full-featured Twitch archive platform, GPL-3.0.

## Twitch-archiving-family comparison

- **Ganymede** — Go/Next.js/Postgres, VOD + live archive, real-time chat playback, watched channels, playlists, GPL-3.0
- **TwitchDownloader** — C# CLI/GUI, manual VOD/clip/chat download tool; MIT
- **Streamlink** — Python, live stream capture to file; no management UI; BSD-2

**Choose Ganymede if:** you want a full self-hosted Twitch archive platform with automatic watched-channel recording, real-time chat playback, a management web UI, and archival-friendly file storage.

## Links

- Repo: <https://github.com/Zibbp/ganymede>
- Wiki: <https://github.com/Zibbp/ganymede/wiki>
- File structure: <https://github.com/Zibbp/ganymede/wiki/File-Structure>
- Storage requirements: <https://github.com/Zibbp/ganymede/wiki/Storage-Requirements>
