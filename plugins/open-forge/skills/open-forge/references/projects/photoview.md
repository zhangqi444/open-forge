---
name: Photoview
description: "Self-hosted photo gallery for photographers — auto-scans folder-of-originals, extracts EXIF + GPS, generates thumbnails, detects faces, displays on world map. Read-only relative to your source photos — doesn't move or modify them. Go + GraphQL + React. GPL-3.0."
---

# Photoview

Photoview is **a photo gallery for self-hosted personal / photographer workflows**. Unlike Immich / PhotoPrism / Nextcloud Photos, Photoview is **read-only** against your photo folder — you point it at a directory structured however you like, and it indexes + displays. It doesn't move files, doesn't want to be your source of truth; it's a *viewer* layered on top of your existing photo library.

Ideal for: photographers who already organize photos in folders on a NAS, want a pretty web gallery, and don't want upload-import workflows.

Features:

- **Read-only** album scanner — directory = album; nested = nested albums
- **RAW support** — CR2, NEF, ARW, DNG, etc. (via `libraw`); generates JPEG thumbnails
- **EXIF metadata** — camera, lens, shutter, aperture, ISO, focal length
- **GPS / Map view** — plots photos on a Leaflet world map
- **Face detection + recognition** (optional, resource-heavy) — uses dlib/face_recognition
- **Video support** — MP4/MOV/AVI with thumbnail + streaming
- **Sharing** — per-album share links (with optional password)
- **Multi-user** — each user has their own albums
- **Download originals** — direct original file download
- **Fast UI** — GraphQL backend + React frontend; snappy browse
- **PWA** — install as mobile app
- **Timeline** — chronological view across all albums

- Upstream repo: <https://github.com/photoview/photoview>
- Website: <https://photoview.github.io>
- Docs: <https://photoview.github.io/docs/>
- Docker Hub: <https://hub.docker.com/r/viktorstrate/photoview>
- Demo: <https://photos.qpqp.dk>

## Architecture in one minute

- **Backend**: Go; exposes GraphQL API
- **Frontend**: React
- **DB**: **MySQL / MariaDB** or **Postgres** or **SQLite** (SQLite for small/personal use)
- **Storage model**: **read-only scan** of a host directory mounted into the container
- **Media processing**: generates thumbnails + JPEG previews + video thumbs into a cache dir; originals never touched
- **Resource**: thumbnail generation is CPU-heavy on first scan; steady state is light

## Compatible install methods

| Infra          | Runtime                                                 | Notes                                                                       |
| -------------- | ------------------------------------------------------- | --------------------------------------------------------------------------- |
| Single VM      | **Docker Compose (`viktorstrate/photoview`)**               | **Upstream-documented primary path**                                            |
| Single VM      | Native Go binary (from releases)                                    | Cross-platform                                                                          |
| Synology / QNAP | Docker via Container Manager                                              | Common NAS deployment                                                                              |
| Raspberry Pi   | arm/arm64 Docker                                                                    | Face recognition heavy; disable on Pi                                                                          |
| Kubernetes     | Community manifests                                                                             | Works                                                                                                      |
| Managed        | — (no SaaS)                                                                                             |                                                                                                                      |

## Inputs to collect

| Input               | Example                                       | Phase       | Notes                                                                            |
| ------------------- | --------------------------------------------- | ----------- | -------------------------------------------------------------------------------- |
| Photo folder        | `/mnt/photos`                                     | Source      | **Mount read-only**                                                                   |
| Cache folder        | `/app/cache`                                            | Storage     | Thumbnails + previews; grows significantly (25-40% of originals)                              |
| DB                  | SQLite (simple) / MySQL / Postgres                           | DB          | Default SQLite fine for <100k photos                                                                      |
| MAPBOX_TOKEN (opt)  | token from mapbox.com                                                | Feature     | For map view tiles (optional; OpenStreetMap fallback)                                                                |
| Admin user          | created on first boot                                                            | Bootstrap   | First-visit wizard                                                                                                   |
| Port                | `80` in-container                                                                       | Network     | Map to host port                                                                                                              |
| Face recognition    | ENABLE_FACE_RECOGNITION=1                                                                        | Feature     | Heavy RAM/CPU; disable on low-resource                                                                                                |

## Install via Docker Compose

Upstream's `docker-compose.example.yml` — abbreviated:

```yaml
services:
  photoview:
    image: viktorstrate/photoview:2.5             # pin
    container_name: photoview
    restart: unless-stopped
    ports:
      - "8080:80"
    depends_on:
      - db
    environment:
      PHOTOVIEW_DATABASE_DRIVER: mysql
      PHOTOVIEW_MYSQL_URL: photoview:photoview@tcp(db)/photoview
      PHOTOVIEW_LISTEN_IP: 0.0.0.0
      PHOTOVIEW_LISTEN_PORT: 80
      PHOTOVIEW_MEDIA_CACHE: /app/cache
      MAPBOX_TOKEN: your-mapbox-token-or-leave-empty
    volumes:
      - ./cache:/app/cache
      - /mnt/photos:/photos:ro                    # READ-ONLY mount
  db:
    image: mariadb:11
    restart: unless-stopped
    environment:
      MARIADB_RANDOM_ROOT_PASSWORD: "yes"
      MARIADB_DATABASE: photoview
      MARIADB_USER: photoview
      MARIADB_PASSWORD: photoview
    volumes:
      - ./db:/var/lib/mysql
```

## First boot

1. `docker compose up -d`; wait for MariaDB init
2. Browse `http://<host>:8080/` → initial setup wizard → create admin account
3. **Settings → User Settings → Add Root Path** → `/photos` (the container path)
4. Click **Scan All** — initial indexing begins (minutes to hours depending on library size)
5. Thumbnails populate; browse by album
6. Enable face recognition (if hardware allows) + configure users

## Data & config layout

- Source: **read-only** — never modified
- `cache/` — generated thumbnails / JPEG previews / video thumbs (can regenerate if lost)
- MariaDB / Postgres / SQLite — metadata + EXIF + user data
- No config file; env vars only

## Backup

```sh
# DB
docker exec pv-db mysqldump -u photoview -pphotoview photoview | gzip > pv-$(date +%F).sql.gz
# Photos themselves — back up separately (Photoview is just a viewer)
# Cache — regeneratable; skip
```

**The important thing is your source photos** — Photoview doesn't touch them, so back those up via your normal NAS / rsync / Borg flow.

## Upgrade

1. Releases: <https://github.com/photoview/photoview/releases>. Moderately active.
2. Docker: bump tag → migrations auto.
3. Re-scan not needed typically; some schema changes may regenerate thumbnails.

## Gotchas

- **Mount your photo folder READ-ONLY.** `:ro` suffix on volume. Photoview doesn't need write access; read-only prevents accidents.
- **Cache grows to 25-40% of originals.** On a 500 GB library, expect ~150-200 GB of thumbnails + previews. Plan disk.
- **Initial scan is long** — 10k photos = minutes; 100k photos = hours; 500k photos = overnight. Don't cancel.
- **RAW processing is CPU-intensive.** Each RAW → JPEG preview takes seconds-per-image. First scan can pin a core for hours.
- **Face recognition resource**: dlib's face_recognition uses ~200 MB per process + GPU acceleration is optional. Disable if on RPi/low-resource.
- **Face recognition quality**: good but not perfect. Manual merge/split needed. Supports labeling.
- **Video thumbnails**: requires ffmpeg (bundled in Docker image). Heavy for many videos.
- **Mapbox token** — optional; without it you get OpenStreetMap tiles. Mapbox quality is slightly better; free tier is fine for personal.
- **Sharing**: share links can be password-protected. Disable public sharing if not needed.
- **Multi-user isolation**: each user has own root paths. Permissions respected across directory structure.
- **No upload UI.** Photoview is read-only; to add photos, copy to your source folder + rescan. If you want an "upload and have the gallery auto-sort," use Immich/PhotoPrism.
- **No face-based timeline** (at version 2.x) — face groups are a view, not a filter for timeline.
- **Periodic rescan**: cron or webhook to trigger rescan after new photos arrive. Settings → Periodic Scanner.
- **Camera model heuristics**: Photoview relies on EXIF; cameras with no EXIF = no metadata.
- **GPS privacy**: if your library has GPS-tagged photos you share publicly, strip GPS first (or use album privacy settings).
- **Mobile**: PWA works well; no native apps.
- **Comparison to Immich / PhotoPrism**:
  - **Immich** = Google Photos replacement; upload-centric; ML search, face recognition, geolocation; mobile apps with auto-backup
  - **PhotoPrism** = photo library manager; copy-into-library model; indexing + tagging
  - **Photoview** = viewer only; read-only; minimal intrusion
  - **Photoview is unique for "don't touch my photos, just show them."**
- **License**: GPL-3.0.
- **Alternatives worth knowing:**
  - **Immich** — full Google Photos alternative with mobile upload; current star king (separate recipe)
  - **PhotoPrism** — library manager with ML; commercial tier for some features (separate recipe)
  - **Lychee** — photo management + albums + sharing; PHP (separate recipe)
  - **Piwigo** — classic PHP photo gallery; very mature (separate recipe)
  - **Chevereto** — commercial; free self-host for basics
  - **Nextcloud Photos** — if you already run Nextcloud
  - **Damselfly** — read-only alternative similar to Photoview; .NET
  - **OpenPhoto / Trovebox** — older; mostly dormant
  - **Choose Photoview if:** you already organize photos in folders + want read-only viewer, don't want upload workflow.
  - **Choose Immich if:** you want Google Photos replacement with mobile auto-backup.
  - **Choose PhotoPrism if:** you want ML tagging + library-management UX.
  - **Choose Lychee/Piwigo if:** you want traditional gallery with albums + sharing.

## Links

- Repo: <https://github.com/photoview/photoview>
- Website: <https://photoview.github.io>
- Docs: <https://photoview.github.io/docs/>
- Installation (Docker): <https://photoview.github.io/docs/installation-docker>
- Demo: <https://photos.qpqp.dk>
- Docker Hub: <https://hub.docker.com/r/viktorstrate/photoview>
- Releases: <https://github.com/photoview/photoview/releases>
- Discord: <https://discord.gg/jQ392948u9>
- Immich (alt): <https://immich.app>
- PhotoPrism (alt): <https://photoprism.app>
- Lychee (alt): <https://lycheeorg.github.io>
- Piwigo (alt): <https://piwigo.org>
- Damselfly (alt): <https://github.com/Webreaper/Damselfly>
