---
name: ChannelTube
description: YouTube channel synchronization tool using yt-dlp. Subscribe to channels, auto-download new videos and audio, schedule syncs, and configure formats. MIT licensed.
website: https://github.com/TheWicklowWolf/ChannelTube
source: https://github.com/TheWicklowWolf/ChannelTube
license: MIT
stars: 301
tags:
  - youtube
  - downloader
  - media-management
  - yt-dlp
platforms:
  - Docker
---

# ChannelTube

ChannelTube is a self-hosted tool for synchronizing YouTube channels using yt-dlp. Subscribe to channels, configure video/audio format preferences, schedule automatic syncs at specified hours, and download both video and audio to separate directories. Web UI for channel management.

Source: https://github.com/TheWicklowWolf/ChannelTube
Docker Hub: https://hub.docker.com/r/thewicklowwolf/channeltube

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker | Single container, all-in-one |

## Inputs to Collect

**Phase: Planning**
- Path for video downloads
- Path for audio downloads
- Path for config persistence
- Sync schedule hours (e.g. `2, 20` for 2 AM and 8 PM)
- Video/audio format IDs (yt-dlp format codes; defaults: video `137`, audio `140`)

## Software-Layer Concerns

**Docker Compose:**

```yaml
services:
  channeltube:
    image: thewicklowwolf/channeltube:latest
    container_name: channeltube
    volumes:
      - /path/to/config:/channeltube/config
      - /data/media/video:/channeltube/downloads
      - /data/media/audio:/channeltube/audio_downloads
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "5000:5000"
    restart: unless-stopped
```

**Environment variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| PUID | User ID for file ownership | 1000 |
| PGID | Group ID for file ownership | 1000 |
| video_format_id | yt-dlp format ID for video | 137 |
| audio_format_id | yt-dlp format ID for audio | 140 |
| defer_hours | Hours to defer downloads | 0 |
| thread_limit | Max concurrent downloads | 1 |
| fallback_vcodec | Fallback video codec | vp9 |
| fallback_acodec | Fallback audio codec | mp4a |
| subtitles | Subtitle handling: `none`, `embed`, `external` | none |
| subtitle_languages | Comma-separated subtitle languages | en |
| include_id_in_filename | Append video ID to filename | false |
| short_video_cutoff | Min video length in seconds (shorter videos skipped) | 180 |
| auto_update_hour | Hour (0–23) to auto-update yt-dlp daily | disabled |
| ytdlp_update_type | yt-dlp update channel: `stable` or `nightly` | stable |

**Sync schedule:** Set via the web UI — comma-separated 24h hours (e.g. `2, 14, 20`).

**Web UI:** Open `http://your-server:5000` to add/manage channel subscriptions and view sync status.

**Format IDs:** yt-dlp format codes — `137` is 1080p MP4 video (no audio), `140` is m4a audio. For combined video+audio, use formats like `bestvideo+bestaudio`. Check `yt-dlp -F <url>` for available formats.

## Upgrade Procedure

1. `docker pull thewicklowwolf/channeltube:latest`
2. `docker compose down && docker compose up -d`
3. Check releases: https://github.com/TheWicklowWolf/ChannelTube/releases

## Gotchas

- **yt-dlp changes frequently**: YouTube regularly changes its API; yt-dlp releases fixes quickly — keep it updated via `auto_update_hour` or regular image pulls
- **Format availability**: Format ID `137` (1080p) may not be available for all videos; set `fallback_vcodec` for graceful degradation
- **PUID/PGID**: Set to match the owner of your media directories to avoid permission issues
- **No authentication**: ChannelTube's web UI has no built-in auth — protect port 5000 with a reverse proxy + auth if exposed
- **Separate video/audio dirs**: Video and audio are downloaded to separate volume mounts — wire both up correctly

## Links

- Upstream README: https://github.com/TheWicklowWolf/ChannelTube/blob/main/README.md
- Docker Hub: https://hub.docker.com/r/thewicklowwolf/channeltube
- Releases: https://github.com/TheWicklowWolf/ChannelTube/releases
- yt-dlp format reference: https://github.com/yt-dlp/yt-dlp#format-selection
