---
name: Spooty
description: "Self-hosted Spotify downloader via YouTube. Docker. NestJS/Angular + SQLite + Redis. Raiper34/spooty. Download tracks/playlists/albums from Spotify URLs; playlist subscriptions; multiple formats (mp3/flac/opus). MIT."
---

# Spooty

**Self-hosted Spotify downloader.** Paste a Spotify track, playlist, or album URL; Spooty fetches metadata from the Spotify API, finds the matching audio on YouTube, and downloads it. Subscribe to playlists for automatic sync when new tracks are released. Supports multiple formats: mp3, flac, m4a, opus, wav, and more. Built with NestJS and Angular.

Built + maintained by **Raiper34**. MIT license.

> ⚠️ **Download only music you have rights to.** The author explicitly states: do not use this tool for piracy. Use at your own responsibility and in accordance with copyright law.

- Upstream repo: <https://github.com/Raiper34/spooty>
- Docker Hub: <https://hub.docker.com/r/raiper34/spooty>

## Architecture in one minute

- **NestJS** backend + **Angular** frontend
- **SQLite** database (default) for download history
- **Redis** (optional, but recommended via `RUN_REDIS=true` in Docker)
- Port **3000** (web UI + API)
- Downloads stored in mounted `/spooty/backend/downloads` volume
- Uses **yt-dlp** + **ffmpeg** for audio download + conversion
- Resource: **low-medium** — Node.js; bandwidth-bound during downloads

## Compatible install methods

| Infra      | Runtime                  | Notes                              |
| ---------- | ------------------------ | ---------------------------------- |
| **Docker** | `raiper34/spooty`        | **Primary** — Docker Hub           |
| **Source** | Node v20 + npm           | Requires Redis + ffmpeg + Python3  |

## Inputs to collect

| Input                    | Example                   | Phase  | Notes                                                                          |
| ------------------------ | ------------------------- | ------ | ------------------------------------------------------------------------------ |
| `SPOTIFY_CLIENT_ID`      | from Spotify dev dashboard| Auth   | **Required** — Spotify API client ID                                           |
| `SPOTIFY_CLIENT_SECRET`  | from Spotify dev dashboard| Auth   | **Required** — Spotify API client secret                                       |
| Redirect URI (in Spotify)| `http://host:3000/api/callback` | Auth | Configure in Spotify Developer Dashboard to match your Spooty URL             |
| Downloads path           | `/path/on/host:/spooty/backend/downloads` | Storage | Where downloaded files land |

## Spotify App Setup (required)

1. Go to <https://developer.spotify.com/dashboard>
2. Sign in with your Spotify account
3. Create a new application
4. Copy **Client ID** and **Client Secret**
5. Add Redirect URI: `http://your-spooty-host:3000/api/callback`

## Install via Docker

```bash
docker run -d -p 3000:3000 \
  -v /path/to/downloads:/spooty/backend/downloads \
  -e SPOTIFY_CLIENT_ID=your_client_id \
  -e SPOTIFY_CLIENT_SECRET=your_client_secret \
  -e RUN_REDIS=true \
  raiper34/spooty:latest
```

Or Docker Compose:

```yaml
services:
  spooty:
    image: raiper34/spooty:latest
    container_name: spooty
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./downloads:/spooty/backend/downloads
    environment:
      - SPOTIFY_CLIENT_ID=your_client_id
      - SPOTIFY_CLIENT_SECRET=your_client_secret
      - RUN_REDIS=true          # Start Redis inside container
      - FORMAT=mp3              # mp3, flac, opus, m4a, wav, etc.
      # - QUALITY=320           # Audio quality (VBR 0-9 or bitrate)
      # - YT_DOWNLOADS_PER_MINUTE=3  # Rate limit YouTube downloads
```

Visit `http://localhost:3000`.

## First boot

1. Set `SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET`.
2. Configure Redirect URI in Spotify Developer Dashboard.
3. `docker run` or `docker compose up -d`.
4. Visit `http://localhost:3000`.
5. Authenticate with Spotify (first time — OAuth flow).
6. Paste a Spotify track, playlist, or album URL → click Download.
7. (Optional) Subscribe to playlists for automatic sync.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SPOTIFY_CLIENT_ID` | — | **Required** — Spotify app client ID |
| `SPOTIFY_CLIENT_SECRET` | — | **Required** — Spotify app client secret |
| `FORMAT` | `mp3` | Download format: `mp3`, `flac`, `m4a`, `opus`, `vorbis`, `wav`, `alac`, `aac` |
| `QUALITY` | unset | Audio quality: VBR 0–9 or specific bitrate (e.g. `320`) |
| `RUN_REDIS` | `false` | Start Redis inside the container — recommended for Docker |
| `REDIS_HOST` | `localhost` | External Redis host (if not using `RUN_REDIS`) |
| `REDIS_PORT` | `6379` | External Redis port |
| `YT_DOWNLOADS_PER_MINUTE` | `3` | Max YouTube downloads per minute (rate limit) |
| `YT_COOKIES` | — | YouTube cookies to bypass restrictions (see README) |
| `DB_PATH` | `./config/db.sqlite` | SQLite database path |
| `DOWNLOADS_PATH` | `./downloads` | Downloaded files destination |
| `PORT` | `3000` | Server port |

## Gotchas

- **Spotify API key is required.** Spooty uses the Spotify API only for metadata (track name, artist, album, cover art) — it doesn't download from Spotify. The API key is free for personal use.
- **Redirect URI must match exactly.** The OAuth callback URL configured in the Spotify Developer Dashboard must exactly match the URL Spooty uses. For a self-hosted instance, update the Redirect URI in the dashboard to your public domain.
- **YouTube is the actual download source.** Spooty searches YouTube for the best match to the Spotify track metadata and downloads from there. Match quality depends on YouTube availability — rare tracks may match poorly or not at all.
- **`RUN_REDIS=true` for Docker.** By default, `RUN_REDIS=false` — Spooty expects an external Redis instance. Set `RUN_REDIS=true` to run Redis inside the container (the Docker image includes Redis). For production, a separate Redis container is cleaner.
- **`YT_DOWNLOADS_PER_MINUTE=3` (default).** YouTube rate-limits downloads. Don't set this too high — YouTube may block your IP or serve CAPTCHAs. `3` is conservative and reliable.
- **YouTube cookies for restrictions.** Some YouTube content requires cookies (region-locked, age-gated, YouTube Premium content). If downloads fail, try passing your browser's YouTube cookies via `YT_COOKIES`. See the README for the exact format.
- **Format availability.** opus, flac, and alac require transcoding (ffmpeg). mp3 and m4a are widely available without transcoding. Format availability depends on the source YouTube stream.
- **Playlist subscriptions.** When subscribed, Spooty periodically checks Spotify for new tracks in the playlist and downloads them automatically. Polling interval is configurable.

## Backup

```sh
docker compose stop spooty
sudo tar czf spooty-$(date +%F).tgz downloads/ # plus your DB path
docker compose start spooty
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active NestJS + Angular development, Docker Hub, multiple audio formats, playlist subscriptions, YouTube cookies support. Solo-maintained by Raiper34. MIT license.

## Spotify-downloader-family comparison

- **Spooty** — NestJS+Angular, web UI, playlist subscriptions, multiple formats, Docker, MIT
- **spotDL** — Python CLI; no web UI; similar Spotify→YouTube approach; very popular
- **Lidarr** — C#, artist-based music acquisition via Usenet/torrent; no Spotify integration
- **Explo** — Go, ListenBrainz-based discovery downloader; different trigger (recommendations vs explicit links)

**Choose Spooty if:** you want a self-hosted web UI for downloading Spotify tracks/playlists/albums via YouTube, with playlist subscriptions and multiple output formats.

## Links

- Repo: <https://github.com/Raiper34/spooty>
- Docker Hub: <https://hub.docker.com/r/raiper34/spooty>
- Spotify Developer Dashboard: <https://developer.spotify.com/dashboard>
