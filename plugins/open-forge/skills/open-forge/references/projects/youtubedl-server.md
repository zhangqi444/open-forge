---
name: youtubedl-server
description: YoutubeDL-Server recipe for open-forge. Web and REST interface for yt-dlp (or youtube-dl). Paste a URL, download to server. Profiles for different output formats. Docker. Source: https://github.com/nbr23/youtube-dl-server
---

# YoutubeDL-Server

Simple web and REST interface for downloading videos from YouTube and other sites onto a server using yt-dlp. Paste a URL in the browser UI or POST to the REST API; files are saved to a configured directory. Supports download profiles (e.g. audio podcast, video) for different output formats. Python + Starlette. MIT licensed.

Upstream: <https://github.com/nbr23/youtube-dl-server>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (nbr23/youtube-dl-server) | Recommended |
| Any | Docker Compose | With config.yml override |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Download directory path | Where videos are saved on the host |
| config | Port | Default: 8080 |
| config (optional) | config.yml | Override format, output templates, profiles |

## Software-layer concerns

### Image tags

| Tag | Backend |
|---|---|
| `nbr23/youtube-dl-server:latest` or `:yt-dlp` | yt-dlp (recommended) |
| `nbr23/youtube-dl-server:youtube-dl` | youtube-dl (outdated, last release 2021) |

### config.yml

Mount a custom `config.yml` at `/app_config/config.yml` to override defaults:

```yaml
ydl_server:
  port: 8080
  host: 0.0.0.0
  debug: False
  metadata_db_path: '/youtube-dl/.ydl-metadata.db'
  output_playlist: '/youtube-dl/%(playlist_title)s [%(playlist_id)s]/%(title)s.%(ext)s'
  max_log_entries: 100
  default_format: video/best
  download_workers_count: 2

ydl_options:
  output: '/youtube-dl/%(title)s [%(id)s].%(ext)s'
  cache-dir: '/youtube-dl/.cache'
  ignore-errors: True

profiles:
  podcast:
    name: 'Audio Podcasts'
    ydl_options:
      output: '/youtube-dl/Podcast/%(title)s [%(id)s].%(ext)s'
      format: bestaudio/best
      extract-audio: True
      audio-format: mp3
      add-metadata: True
      embed-thumbnail: True
```

### Data dir

| Host path | Container path | Description |
|---|---|---|
| $HOME/youtube-dl | /youtube-dl | Download destination + DB + cache |

## Install — Docker CLI

```bash
# yt-dlp (recommended)
docker run -d \
  --name youtube-dl \
  --restart unless-stopped \
  -p 8080:8080 \
  -v $HOME/youtube-dl:/youtube-dl \
  nbr23/youtube-dl-server:yt-dlp
```

## Install — Docker Compose

```yaml
services:
  youtube-dl:
    image: nbr23/youtube-dl-server:latest
    restart: always
    ports:
      - 8080:8080
    volumes:
      - $HOME/youtube-dl:/youtube-dl
      - ./config.yml:/app_config/config.yml:ro
```

Access the web UI at http://yourserver:8080.

## REST API

```bash
# Submit a URL for download
curl -X POST http://localhost:8080/api/downloads \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"}'

# Check download queue/status
curl http://localhost:8080/api/downloads
```

## Upgrade procedure

```bash
docker pull nbr23/youtube-dl-server:latest
docker compose up -d
# or: docker rm -f youtube-dl && re-run docker run
```

## Gotchas

- Use `:yt-dlp` tag — the `:youtube-dl` tag uses the original youtube-dl which hasn't had a release since 2021 and breaks on many sites. yt-dlp is actively maintained and works with far more sites.
- yt-dlp is a third-party dependency that can break when YouTube changes their format — update the container regularly if downloads suddenly fail.
- The download directory (`/youtube-dl`) must be writable — mount it with a writable host path.
- `download_workers_count` defaults to 2 — increase carefully; too many parallel yt-dlp processes can get rate-limited.
- No built-in authentication — deploy behind a reverse proxy with auth if this is exposed on a network you don't fully trust.

## Links

- Source: https://github.com/nbr23/youtube-dl-server
- DockerHub: https://hub.docker.com/r/nbr23/youtube-dl-server
- yt-dlp: https://github.com/yt-dlp/yt-dlp
