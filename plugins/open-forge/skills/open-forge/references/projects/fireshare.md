---
name: Fireshare
description: "Self-hosted video sharing platform for game clips and personal videos. Docker. Python/Flask + SQLite. ShaneIsrael/fireshare. Sharable links, category feeds, Steam game art, 720p/1080p transcoding, PUID/PGID."
---

# Fireshare

**Self-hosted app for sharing your personal video clips.** Upload game clips, screen recordings, or any videos; get unique sharable links; browse by game category with Steam grid art; auto-scan directories for new videos; optional 720p/1080p transcoding (with NVENC GPU acceleration support). Single-user admin + public viewer. Built with privacy in mind: your clips on your server.

Built + maintained by **ShaneIsrael**. MIT license.

- Upstream repo: <https://github.com/ShaneIsrael/fireshare>
- Docker Hub: <https://hub.docker.com/r/shaneisrael/fireshare>
- Live demo (ephemeral): available via README link

## Architecture in one minute

- **Python / Flask** backend + JavaScript frontend
- **SQLite** database
- Port **8080** (mapped to container port 80)
- Videos stored in mounted `/videos` volume; processed metadata in `/processed`; thumbnails in `/data`
- Steam Grid DB integration for game artwork (requires free API key)
- Transcoding via ffmpeg (`ENABLE_TRANSCODING=true`, optional NVENC GPU pass-through)
- Resource: **low baseline**; medium when transcoding

## Compatible install methods

| Infra        | Runtime                       | Notes                                            |
| ------------ | ----------------------------- | ------------------------------------------------ |
| **Docker**   | `shaneisrael/fireshare`       | **Primary** — Docker Hub                         |

## Inputs to collect

| Input                         | Example                          | Phase    | Notes                                                                                   |
| ----------------------------- | -------------------------------- | -------- | --------------------------------------------------------------------------------------- |
| `ADMIN_USERNAME`              | `admin`                          | Auth     | Set on first run; can remove var after first login                                      |
| `ADMIN_PASSWORD`              | strong password                  | Auth     | **Change from default** — default is `admin`                                            |
| `SECRET_KEY`                  | random string                    | Security | Flask session secret; **required** — replace the placeholder                           |
| `DOMAIN`                      | `clips.example.com`              | Network  | Your public domain (no http/https); for OpenGraph share previews                        |
| Videos dir                    | `/path/to/videos:/videos`        | Storage  | Where your video files live on the host                                                 |
| `STEAMGRIDDB_API_KEY` (opt.)  | from steamgriddb.com             | Feature  | For automatic game artwork on category pages; free                                      |
| `ENABLE_TRANSCODING` (opt.)   | `false` → `true`                 | Feature  | Generates 720p/1080p variants via ffmpeg                                                |

## Install via Docker

```yaml
services:
  fireshare:
    container_name: fireshare
    image: shaneisrael/fireshare:latest
    ports:
      - "8080:80"
    volumes:
      - ./data:/data
      - ./processed:/processed
      - ./videos:/videos
      - ./images:/images
    environment:
      - ADMIN_USERNAME=admin
      - ADMIN_PASSWORD=changeme          # CHANGE THIS
      - SECRET_KEY=replace_with_random   # CHANGE THIS
      - DOMAIN=clips.example.com
      - MINUTES_BETWEEN_VIDEO_SCANS=5
      - THUMBNAIL_VIDEO_LOCATION=0
      - PUID=1000
      - PGID=1000
      - ENABLE_TRANSCODING=false
      # - STEAMGRIDDB_API_KEY=your_key
    restart: unless-stopped
```

Visit `http://localhost:8080`.

## First boot

1. Set `ADMIN_PASSWORD` + `SECRET_KEY` + `DOMAIN` before starting.
2. `docker compose up -d`.
3. Visit `http://localhost:8080` → log in with your admin credentials.
4. **Remove `ADMIN_USERNAME`/`ADMIN_PASSWORD`** env vars after first login (security best practice — credentials stored in DB now).
5. Drop video files into the `./videos/` directory.
6. Fireshare auto-scans every `MINUTES_BETWEEN_VIDEO_SCANS` minutes; or trigger manually from admin panel.
7. Videos appear in the library; admin can create shareable links.
8. Configure game categories + SteamGridDB API key for artwork.
9. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| Video library | Displays all videos in your mounted `/videos` dir |
| Sharable links | Generate unique links per video for public sharing |
| Game categories | Group clips by game name; SteamGridDB artwork |
| Auto-scan | Polls `/videos` every N minutes for new files |
| Thumbnail control | `THUMBNAIL_VIDEO_LOCATION` (0–100%) — where to grab thumbnail frame |
| Transcoding | 720p + 1080p variants via ffmpeg; optional NVENC GPU |
| Visibility control | Per-video public/private toggle |
| OpenGraph | Rich preview cards when sharing links (requires `DOMAIN` set) |
| Analytics (optional) | Inject any analytics provider script via `ANALYTICS_TRACKING_SCRIPT` |
| PUID/PGID | Match container UID/GID to host file owner |

## Data & config layout

- `./data/` — SQLite DB + thumbnails + Fireshare state
- `./processed/` — transcoded variants (if enabled)
- `./videos/` — source video files (read by Fireshare; not moved/renamed)
- `./images/` — game artwork cache

## Backup

```sh
docker compose stop fireshare
sudo tar czf fireshare-$(date +%F).tgz data/ processed/ images/
docker compose start fireshare
# Videos are in ./videos/ — back up separately (they're your source files)
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Gotchas

- **Remove admin creds from env after first run.** The README explicitly says: after first login, remove `ADMIN_USERNAME` and `ADMIN_PASSWORD` from the compose file and restart. The credentials persist in the DB; leaving them in env is a security risk (visible in `docker inspect`).
- **`SECRET_KEY` must be changed.** Flask uses it for session signing. Default placeholder = anyone who knows the default can forge session cookies.
- **`DOMAIN` is for OpenGraph only.** It doesn't affect routing or TLS — it's embedded in the HTML `<meta>` tags for share-link previews. Set it to your public domain (without `http://`).
- **Transcoding doubles your storage.** 720p + 1080p variants are generated alongside originals. Plan disk accordingly before enabling.
- **NVENC GPU transcoding.** Requires `runtime: nvidia` in compose + `nvidia-container-toolkit` on the host + an NVIDIA GPU. Comment these in from the upstream compose example.
- **Auto-scan is polling-based.** New files appear after `MINUTES_BETWEEN_VIDEO_SCANS` minutes. For immediate addition, use the admin panel's manual rescan button.
- **`THUMBNAIL_VIDEO_LOCATION=0`** grabs the very first frame — useful for gameplay recordings that have intros. `50` grabs the middle frame. Adjust to taste.
- **SteamGridDB rate limits.** The API is free but has rate limits. If you have many games, initial artwork fetch may take time. Images are cached in `./images/`.
- **Single admin user.** No multi-user with roles. One admin manages the library; viewers access via share links or the public browse page.

## Project health

Active Python/Flask development, Docker Hub, NVENC support, SteamGridDB integration. Solo-maintained by ShaneIsrael. MIT license.

## Video-sharing-family comparison

- **Fireshare** — Python+SQLite, game clip focus, SteamGridDB art, transcoding, share links, MIT
- **Tube Archivist** — ElasticSearch+Postgres, YouTube-archive focused, heavier
- **PeerTube** — ActivityPub federated video platform, full social features, much heavier
- **Immich** — photo-first but supports video; family photos focus, not gaming clips
- **Jelly Fin** — media server that plays videos; doesn't generate share links

**Choose Fireshare if:** you want a simple self-hosted game clip library with sharable links, Steam game artwork, and optional transcoding — without the complexity of PeerTube.

## Links

- Repo: <https://github.com/ShaneIsrael/fireshare>
- Docker Hub: <https://hub.docker.com/r/shaneisrael/fireshare>
- SteamGridDB API: <https://www.steamgriddb.com/api/v2>
