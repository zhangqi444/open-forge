---
name: StashCast
description: "Save online media (audio/video) for offline use and expose via podcast RSS feeds. Built on Django + yt-dlp + ffmpeg. Single-user. Supports any yt-dlp-compatible URL. Add bookmarklet to stash from browser. Subscribe in any podcast app. Docker Compose with Caddy."
---

# StashCast

StashCast is a **single-user Django web app** that downloads online media (audio/video) from any URL supported by [yt-dlp](https://github.com/yt-dlp/yt-dlp) and exposes it as **podcast RSS/Atom feeds** — so you can watch or listen later in any podcast app (AntennaPod, Overcast, Pocket Casts, etc.).

Use case: a friend sends a YouTube link or podcast episode you want to listen to later, without subscribing to the full show. Stash the URL → it appears in your podcast app.

- Upstream repo: <https://github.com/jonocodes/stashcast>
- Demo: <https://demo.stashcast.net/> (user: demo, pass: omed)
- License: GPL v3

## Architecture

- **Web**: Django app, port 8000
- **Worker**: Huey task queue (background downloads)
- **Static/media server**: Caddy (in Docker setup) or any web server
- **Dependencies**: yt-dlp, ffmpeg (installed in container or system)
- **Storage**: SQLite + local media directory (`STASHCAST_DATA_DIR`)

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Docker Compose | Build from source | Primary — includes Caddy, worker |
| Manual (Python venv) | Python 3.12+ | Requires yt-dlp + ffmpeg installed |

## Inputs to collect

| Input | Example | Phase | Notes |
|---|---|---|---|
| STASHCAST_DATA_DIR | /app/data | storage | Base path; media stored in DATA_DIR/media |
| STASHCAST_USER_TOKEN | random string | auth | API token for bookmarklet and curl stashing |
| LANGUAGE_CODE | en-us | preflight | UI language and subtitle language (en, es, pt) |
| REQUIRE_USER_TOKEN_FOR_FEEDS | false | auth | Set true to require token in RSS feed URLs |
| Admin username + password | via createsuperuser | bootstrap | Access /admin/ management interface |

## Install via Docker Compose

From upstream: <https://github.com/jonocodes/stashcast/blob/main/docker-compose.yml>

```bash
git clone https://github.com/jonocodes/stashcast.git
cd stashcast
```

Upstream docker-compose.yml:

```yaml
services:
  caddy:
    image: caddy:2-alpine
    ports:
      - "8000:80"
    volumes:
      - static:/srv/static:ro
      - ./data_docker/media:/srv/media:ro
    configs:
      - source: caddyfile
        target: /etc/caddy/Caddyfile
    depends_on:
      - web

  web:
    build:
      context: .
    container_name: stashcast_web
    environment:
      STASHCAST_DATA_DIR: /app/data_docker
    volumes:
      - ./data_docker:/app/data_docker
      - static:/app/staticfiles

  worker:
    build:
      context: .
    container_name: stashcast_worker
    command: python manage.py run_huey
    depends_on:
      - web
    environment:
      STASHCAST_DATA_DIR: /app/data_docker
    volumes:
      - ./data_docker:/app/data_docker

volumes:
  static:
```

```bash
# Start services
docker compose up -d

# Set up DB and create superuser
docker compose run web python manage.py migrate
docker compose run web python manage.py createsuperuser

# Open http://localhost:8000
```

## Install without Docker (Python venv)

```bash
# Install system deps: yt-dlp, ffmpeg
sudo apt install ffmpeg
pip install yt-dlp

# Set up Python env
python -m venv venv && source venv/bin/activate
cp .env.example .env   # edit: set STASHCAST_DATA_DIR, STASHCAST_USER_TOKEN

# Install deps and configure
just setup-with-packages     # or: pip install -r requirements.txt && python manage.py migrate

# Create admin user
./manage.py createsuperuser

# Run (3 processes)
./manage.py runserver         # Terminal 1: Django on :8000
./manage.py run_huey          # Terminal 2: background worker
```

## Environment variables

| Variable | Default | Notes |
|---|---|---|
| STASHCAST_DATA_DIR | /app/data | Base path for all data (DB + media) |
| STASHCAST_USER_TOKEN | — | API token for /stash/ endpoint and bookmarklet |
| LANGUAGE_CODE | en-us | UI and subtitle language (en, es, pt) |
| REQUIRE_USER_TOKEN_FOR_FEEDS | false | If true, feed URLs must include token param |

## Usage

### Stashing media

```bash
# API endpoint
curl "http://localhost:8000/stash/?token=YOUR_USER_TOKEN&url=https://youtube.com/watch?v=...&type=auto"
# type: auto | audio | video
```

Or use the **bookmarklet**: go to `http://localhost:8000/admin/tools/bookmarklet/` and drag the bookmarklet to your bookmarks bar. Click it on any page with media.

### Podcast feeds

```
http://localhost:8000/feeds/audio.xml
http://localhost:8000/feeds/video.xml
http://localhost:8000/feeds/combined.xml
# With token protection:
http://localhost:8000/feeds/audio.xml?token=YOUR_USER_TOKEN
```

Add these to any podcast app (AntennaPod, Overcast, Pocket Casts, etc.).

### Admin interface

`http://localhost:8000/admin/` — view media items, monitor downloads, re-fetch failures, regenerate summaries, view logs.

## Features

- Downloads from any yt-dlp-supported URL (YouTube, Vimeo, thousands of sites)
- Direct media URL support
- HTML page with embedded media auto-extraction
- Playlist support
- Podcast feed generation (RSS/Atom) for audio, video, or combined
- Bookmarklet for one-click stashing from browser
- Optional transcoding via ffmpeg
- Extractive summarization from subtitles
- Multi-language UI and subtitles (en, es, pt)
- CLI commands: `stash`, `fetch` for scripting

## Upgrade procedure

```bash
# Docker
git pull
docker compose build
docker compose up -d
docker compose run web python manage.py migrate

# venv
git pull
pip install -r requirements.txt
./manage.py migrate
```

## Gotchas

- Worker process (run_huey) must be running separately — downloads queue in DB but won't execute without it
- Docker compose uses a build (not a pre-built image) — first run takes time to build
- Large video downloads may take time; check worker logs if items stay "pending"
- yt-dlp is pinned in requirements.txt — update it separately with `yt-dlp -U` or by bumping requirements if sites stop working
- STASHCAST_DATA_DIR must be writable by the web and worker containers (same volume mount)
- For private feeds: REQUIRE_USER_TOKEN_FOR_FEEDS=true; podcast apps that don't support query params in URLs won't work with private feeds

## TODO — verify on subsequent deployments

- Confirm data directory structure on first run (db file location)
- Validate i18n subtitle extraction for non-English content
- Check yt-dlp version compatibility on each new release
