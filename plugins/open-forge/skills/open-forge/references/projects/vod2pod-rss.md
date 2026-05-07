---
name: vod2pod-rss
description: vod2pod-rss recipe for open-forge. Convert YouTube and Twitch channels into podcast RSS feeds. Transcodes VoDs to MP3 on-the-fly, no storage required. Supports standard RSS feeds too. Docker Compose + Redis. Source: https://github.com/madiele/vod2pod-rss
---

# vod2pod-rss

Converts YouTube and Twitch channels (and standard podcast RSS feeds) into proper podcast RSS feeds you can subscribe to in any podcast client. VoDs are transcoded to MP3 192k on-the-fly — no storage needed on the server. Works on Raspberry Pi 3/4. Optional YouTube and Twitch API keys unlock more than 15 results and channel avatars. Built in Rust. MIT licensed.

Upstream: <https://github.com/madiele/vod2pod-rss>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any (amd64/arm64/armv7) | Docker Compose + Redis | Official multi-arch images on DockerHub |
| Raspberry Pi 3/4 | Docker Compose (arm image) | Tested; transcodes reliably on Pi hardware |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port | Default: 80 → 8080 |
| config | Timezone | For log timestamps (e.g. Europe/London) |
| config (optional) | YouTube API key | Removes 15-item limit; enables channel avatar |
| config (optional) | Twitch CLIENT ID + SECRET | For Twitch channel support |
| config (optional) | MP3 bitrate | Default: 192 kbps |

## Software-layer concerns

### Architecture

- vod2pod-rss (Rust) — main app; feed generation + on-the-fly transcoding via yt-dlp + ffmpeg
- Redis — caching for feed results and metadata (included in compose)

### Key env vars

| Var | Description | Default |
|---|---|---|
| YT_API_KEY | YouTube Data API v3 key | (empty — limited to 15 results) |
| TWITCH_SECRET | Twitch API secret | (empty) |
| TWITCH_CLIENT_ID | Twitch API client ID | (empty) |
| MP3_BITRATE | Transcoded stream bitrate (kbps) | 192 |
| TRANSCODE | Enable transcoding (true/false) | true |
| TZ | Log timezone | UTC |
| SUBFOLDER | Root path for reverse proxy (e.g. `/vod2pod`) | / |
| RUST_LOG | Log level: INFO or DEBUG | INFO |
| VOD2POD_RSS_HOST | Bind host | 0.0.0.0 |
| VOD2POD_RSS_PORT | Internal port | 8080 |
| VALID_URL_DOMAINS | Comma-separated allowed domains | YouTube + Twitch |
| CACHE_TTL | Feed cache TTL in seconds | 600 |
| YOUTUBE_YT_DLP_GET_URL_EXTRA_ARGS | Extra yt-dlp args (JSON array) | [] |

### Redis

Redis is used for caching; included in the compose file. Do not change `REDIS_ADDRESS` or `REDIS_PORT` unless also changing the Redis service name/port in compose.

## Install — Docker Compose

```bash
git clone https://github.com/madiele/vod2pod-rss.git
cd vod2pod-rss

# Create .env file for optional API keys
cat > .env << 'EOF'
YT_API_KEY=
TWITCH_SECRET=
TWITCH_CLIENT_ID=
EOF

# Edit docker-compose.yml if needed (port, timezone, bitrate)
docker compose up -d
```

Access the web UI at http://localhost (or your configured port).

**docker-compose.yml (key sections):**
```yaml
services:
  vod2pod:
    image: madiele/vod2pod-rss:latest
    restart: unless-stopped
    depends_on:
      - redis
    ports:
      - "80:8080"
    environment:
      - YT_API_KEY=${YT_API_KEY:-}
      - TWITCH_SECRET=${TWITCH_SECRET:-}
      - TWITCH_CLIENT_ID=${TWITCH_CLIENT_ID:-}
      - TZ=Europe/London
      - MP3_BITRATE=192
      - TRANSCODE=true
      - SUBFOLDER=/

  redis:
    image: "redis:8.4"
    command: redis-server --save 20 1 --loglevel warning
    restart: unless-stopped
```

## Usage

1. Open the web UI (http://yourserver/)
2. Paste a YouTube channel URL or Twitch channel URL
3. Copy the generated RSS link
4. Add the RSS link to any podcast client (Pocket Casts, AntennaPod, Overcast, etc.)

Or directly: `http://yourserver/transcodize_rss?url=https://www.youtube.com/c/channelname`

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
docker system prune   # optional: clean old images
```

## Gotchas

- Without a YouTube API key, feeds are limited to the most recent 15 videos and channel avatars are not shown. Get a free key at https://console.cloud.google.com/ (YouTube Data API v3).
- Twitch requires both `TWITCH_CLIENT_ID` and `TWITCH_SECRET` — get them at https://dev.twitch.tv/console.
- `TRANSCODE=false` generates feed URLs pointing to native video streams — useful if your podcast client can play video natively, but most audio podcast clients need transcoding enabled.
- Set `SUBFOLDER=/vod2pod` if running behind a reverse proxy at a subpath (e.g. `https://example.com/vod2pod`).
- For debugging, set `RUST_LOG=DEBUG` and check logs with `docker compose logs vod2pod`.
- Custom `VALID_URL_DOMAINS` is needed to convert standard RSS/podcast feeds from domains other than YouTube/Twitch.

## Links

- Source: https://github.com/madiele/vod2pod-rss
- DockerHub: https://hub.docker.com/r/madiele/vod2pod-rss
