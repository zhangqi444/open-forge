---
name: HomeTube
description: "Self-hosted universal video downloader web UI for media servers. Docker. Python + Streamlit + yt-dlp. EgalitarianMonkey/hometube. Download and organise ad-free best-quality videos from YouTube and 1800+ platforms directly into Plex/Jellyfin/Emby structure. Playlist sync, subtitle embedding, cookie auth. AGPL-3.0."
---

# HomeTube

**Self-hosted video downloader for your media server.** Web UI for downloading single videos and playlists from YouTube and 1800+ platforms at the best available quality, automatically organised into a Plex/Jellyfin/Emby-compatible directory structure. Blocks ads and sponsors natively via yt-dlp. Supports playlist sync, subtitle embedding, format conversion, and cookie-based authentication for restricted content.

Built + maintained by **EgalitarianMonkey**. AGPL-3.0.

- Upstream repo: <https://github.com/EgalitarianMonkey/hometube>
- Docker: `ghcr.io/egalitarianmonkey/hometube`
- Supported platforms: <https://github.com/EgalitarianMonkey/hometube/blob/main/docs/supported-platforms.md> (1800+)
- Website: <https://hometube.egalitarianmonkey.com>

## Architecture in one minute

- **Python + Streamlit** web UI
- **yt-dlp** under the hood — supports 1800+ platforms
- Port **8501** (configurable via `PORT`)
- Requires three volumes: videos folder, temp download folder, cookies file
- No database — state managed in session/filesystem
- Resource: **low-medium** — Python; CPU spikes during download/conversion

## Compatible install methods

| Infra      | Runtime                           | Notes                                            |
| ---------- | --------------------------------- | ------------------------------------------------ |
| **Docker** | `ghcr.io/egalitarianmonkey/hometube` | **Primary** — single container                |

## Install via Docker Compose

### `.env` file

```env
# Port
PORT=8501

# Timezone
TZ=America/New_York

# Languages
UI_LANGUAGE=en
LANGUAGE_PRIMARY=en
LANGUAGE_PRIMARY_INCLUDE_SUBTITLES=true
LANGUAGES_SECONDARIES=        # optional: comma-separated e.g. fr,es

# Docker host paths (absolute paths on your host)
VIDEOS_FOLDER_DOCKER_HOST=/mnt/data/videos
TMP_DOWNLOAD_FOLDER_DOCKER_HOST=/mnt/data/hometube/tmp
YOUTUBE_COOKIES_FILE_PATH_DOCKER_HOST=/opt/cookies/youtube.txt

# Internal container paths (do not change)
VIDEOS_FOLDER=/data/videos
TMP_DOWNLOAD_FOLDER=/data/tmp
YOUTUBE_COOKIES_FILE_PATH=/config/youtube_cookies.txt
```

### `docker-compose.yml`

```yaml
services:
  hometube:
    image: ghcr.io/egalitarianmonkey/hometube:latest
    container_name: hometube
    env_file: .env
    environment:
      - TZ=${TZ:-America/New_York}
    ports:
      - "${PORT:-8501}:8501"
    volumes:
      - type: bind
        source: ${VIDEOS_FOLDER_DOCKER_HOST:?set VIDEOS_FOLDER_DOCKER_HOST}
        target: /data/videos
      - type: bind
        source: ${TMP_DOWNLOAD_FOLDER_DOCKER_HOST:?set TMP_DOWNLOAD_FOLDER_DOCKER_HOST}
        target: /data/tmp
      - "${YOUTUBE_COOKIES_FILE_PATH_DOCKER_HOST}:/config/youtube_cookies.txt"
    restart: unless-stopped
```

```bash
docker compose up -d
```

Visit `http://localhost:8501`.

> The bind volume `type:` / `source:` / `target:` format enforces that `VIDEOS_FOLDER_DOCKER_HOST` and `TMP_DOWNLOAD_FOLDER_DOCKER_HOST` are set — Docker will fail to start if they're missing, preventing silent errors.

## Key environment variables

| Variable | Required | Notes |
|----------|----------|-------|
| `VIDEOS_FOLDER_DOCKER_HOST` | ✅ | Absolute host path for downloaded videos |
| `TMP_DOWNLOAD_FOLDER_DOCKER_HOST` | ✅ | Absolute host path for temp files during download |
| `YOUTUBE_COOKIES_FILE_PATH_DOCKER_HOST` | Recommended | Absolute host path to `youtube.txt` cookies file |
| `TZ` | Recommended | Your timezone |
| `PORT` | Optional | Host port (default: 8501) |
| `UI_LANGUAGE` | Optional | UI language (default: `en`) |
| `LANGUAGE_PRIMARY` | Optional | Primary download language (default: `en`) |
| `LANGUAGE_PRIMARY_INCLUDE_SUBTITLES` | Optional | Include subtitles in primary language (default: `true`) |
| `LANGUAGES_SECONDARIES` | Optional | Additional subtitle languages, comma-separated |
| `VIDEOS_FOLDER` | Fixed | `/data/videos` — do not change |
| `TMP_DOWNLOAD_FOLDER` | Fixed | `/data/tmp` — do not change |
| `YOUTUBE_COOKIES_FILE_PATH` | Fixed | `/config/youtube_cookies.txt` — do not change |

## Cookies authentication

YouTube increasingly requires authentication for reliable downloads. Export cookies from your browser using a browser extension (e.g. "Get cookies.txt LOCALLY") and place the file at the path set in `YOUTUBE_COOKIES_FILE_PATH_DOCKER_HOST`.

> Note: `COOKIES_FROM_BROWSER` is not supported in Docker — use a cookies file.

## Features overview

| Feature | Details |
|---------|---------|
| Single video download | Paste URL → download best quality video |
| Playlist sync | Download and synchronise entire playlists; track which videos are local |
| Playlist archive | Move removed playlist videos to `Archives/` instead of deleting (enable `PLAYLIST_KEEP_OLD_VIDEOS`) |
| Media server structure | Downloads organised for direct Plex/Jellyfin/Emby library scanning |
| Ad-free | Blocks YouTube ads and SponsorBlock segments natively via yt-dlp |
| Best quality | Advanced quality selection strategy or manual override |
| Subtitle support | Embed subtitles; multiple languages |
| Format conversion | Convert video/audio formats |
| Clip cutting | Cut clips from videos |
| Custom yt-dlp args | Pass any yt-dlp argument (proxy, max-filesize, etc.) |
| Cookie authentication | Use browser cookies for restricted/members-only content |
| Network access | Web UI accessible from any device on your network |
| 1800+ platforms | YouTube, Reddit, Vimeo, Dailymotion, TikTok, Twitch, Facebook, Instagram, and 1800+ more |
| Python/Streamlit | Lightweight web UI; no heavy framework |

## Gotchas

- **`VIDEOS_FOLDER_DOCKER_HOST` and `TMP_DOWNLOAD_FOLDER_DOCKER_HOST` are required.** Docker will refuse to start if these aren't set — by design. Set absolute paths on your host.
- **Cookies file is highly recommended.** Without a cookies file, YouTube downloads may fail or be restricted to lower quality due to bot detection. Export cookies from a logged-in browser session.
- **`COOKIES_FROM_BROWSER` doesn't work in Docker.** Browser-cookie reading requires a running browser on the same machine — not available in a container. Use a cookies file instead.
- **AGPL-3.0 license.** Network-service usage of modified HomeTube requires publishing changes under AGPL-3.0.
- **Temp folder needs space.** Downloads are staged in the temp folder before moving to the videos folder. Ensure both are on volumes with enough space.
- **Streamlit UI.** The UI is built with Streamlit — functional but not a traditional polished web app. It refreshes on interaction.

## Media server integration

The download location (`/data/videos`) is designed to be mounted directly as a Plex/Jellyfin/Emby library:
- Point your media server library at the same path as `VIDEOS_FOLDER_DOCKER_HOST`
- Videos are named and organised for automatic metadata matching

## Backup

```sh
# Videos are your primary backup; temp can be regenerated
# Back up cookies file separately
cp $YOUTUBE_COOKIES_FILE_PATH_DOCKER_HOST youtube-cookies-$(date +%F).txt
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Python/Streamlit/yt-dlp development, AGPL-3.0, Plex/Jellyfin integration.

## Video-downloader-family comparison

- **HomeTube** — Python/Streamlit, web UI, 1800+ platforms, playlist sync, media server structure, AGPL-3.0
- **Pinchflat** — Elixir, YouTube subscription/playlist manager with yt-dlp, media server integration; MIT
- **Metube** — Python/Angular, simple yt-dlp web UI, no media server structure; Apache-2.0
- **Tube Archivist** — Python/Django/Elasticsearch, YouTube-focused archive + management; Apache-2.0
- **TubeSync** — Python, YouTube subscription sync to Plex/Jellyfin; BSD-3

**Choose HomeTube if:** you want a simple web UI to download ad-free videos from YouTube and 1800+ platforms directly into your Plex/Jellyfin/Emby library structure, with playlist sync and subtitle support.

## Links

- Repo: <https://github.com/EgalitarianMonkey/hometube>
- Supported platforms: <https://github.com/EgalitarianMonkey/hometube/blob/main/docs/supported-platforms.md>
- Website: <https://hometube.egalitarianmonkey.com>
