---
name: Hound
description: "Hybrid self-hosted media server. Combines local library playback (like Jellyfin/Plex) with P2P/Debrid streaming (like Stremio). Docker Compose + PostgreSQL. Watch/track movies and TV shows. Android/Android TV clients. Under active development."
---

# Hound

Hound is a **hybrid media server** that merges local-library streaming (à la Jellyfin or Plex) with direct P2P (torrent) and HTTP/Debrid streaming via Stremio addons. You get full control over your media library while also being able to stream content instantly without downloading first — "the best of both worlds."

> ⚠️ **Early development**: Hound is still under heavy development and may contain bugs. Back up data periodically.

Features (per upstream README + docs):

- **Hybrid streaming** — serve your own files *or* stream via P2P / HTTP-Debrid sources through Stremio addons
- **Watch tracking** — Trakt-like tracking auto-applied to everything you watch
- **Custom collections/lists** — curate movie and TV show lists
- **Reviews and comments** — add notes per movie/show
- **Mobile clients** — Android and Android TV APKs available (sideload from releases); iOS/tvOS in progress
- **Fast setup** — "zero to watching content in <10 mins, few dependencies"
- **Planned**: transcoding, data export, detailed watch statistics, recommendations

- Upstream repo: <https://github.com/Hound-Media-Server/hound>
- Docs: <https://hound-media-server.github.io/hound-site/>
- Installation guide: <https://hound-media-server.github.io/hound-site/installation.html>
- App repo (Android/TV clients): <https://github.com/Hound-Media-Server/hound-app>
- Subreddit: <https://www.reddit.com/r/HoundMediaServer/>
- Docker Hub: <https://hub.docker.com/r/houndmediaserver/hound>
- Demo: <https://hound-demo.yuwono.xyz> (user: `github`, pass: `password`)
- License: AGPL-3.0

## Architecture

- **Go** backend (port `2323`)
- **React** frontend (served by the backend)
- **PostgreSQL** — required; separate container
- **Resource**: moderate — Go backend is lightweight; PostgreSQL adds ~256 MB
- **No transcoding yet** (planned) — serves media files directly

## Compatible install methods

| Infra              | Runtime                                | Notes                                |
| ------------------ | -------------------------------------- | ------------------------------------ |
| **Docker Compose** | **`houndmediaserver/hound:latest`**    | **Primary / officially supported**   |
| Source             | Go + Node build                        | Dev only                             |

## Inputs to collect

| Input                  | Example                        | Phase     | Notes                                                              |
| ---------------------- | ------------------------------ | --------- | ------------------------------------------------------------------ |
| Domain / IP            | `hound.example.com`            | URL       | Reverse proxy recommended for TLS; bare IP+port works too          |
| `POSTGRES_PASSWORD`    | strong random string           | DB        | Must match in both `hound-postgres` and `hound-server` services    |
| `HOUND_SECRET`         | strong random string           | Security  | JWT signing secret; rotate to invalidate all sessions              |
| Media library path(s)  | `/mnt/media/movies`            | Storage   | Optional — mount local files as External Library                   |

## Install via Docker Compose

From the [upstream installation guide](https://hound-media-server.github.io/hound-site/installation.html):

```yaml
services:
  hound-postgres:
    container_name: hound-postgres
    image: postgres:18
    environment:
      POSTGRES_DB: hound_db
      POSTGRES_USER: hound
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}   # change from default
    volumes:
      - ./hound-data/postgres_data:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U hound -d hound_db"]
      interval: 5s
      timeout: 5s
      retries: 5

  hound-server:
    container_name: hound-server
    image: houndmediaserver/hound:latest
    depends_on:
      hound-postgres:
        condition: service_healthy
    ports:
      - "2323:2323"
    environment:
      - POSTGRES_DB=hound_db
      - POSTGRES_USER=hound
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}  # must match above
      - HOUND_SECRET=${HOUND_SECRET}             # JWT signing secret
    volumes:
      - ./hound-data:/app/Hound Data
      # Optional: mount your existing media library
      # - /path/to/movies:/app/External Library/Movies
      # - /path/to/shows:/app/External Library/TV Shows
```

Store secrets in a `.env` file next to `docker-compose.yml`:

```env
POSTGRES_PASSWORD=<strong-random-password>
HOUND_SECRET=<strong-random-secret>
```

Generate values with: `openssl rand -hex 32`

Start the stack:

```bash
docker compose up -d
```

## First boot

1. Open `http://<host>:2323`
2. Log in with default credentials: `admin` / `password`
3. **Change the admin password immediately** (Settings → Profile)
4. Follow the [provider setup guide](https://hound-media-server.github.io/hound-site/provider.html) to configure your first streaming source (Debrid or torrent provider)
5. Optionally mount your local media library via the volume mounts above and add it in Settings → Library

## Mobile clients

Android and Android TV APKs are distributed via the [hound-app releases page](https://github.com/Hound-Media-Server/hound-app/releases) — sideload the `.apk` file. iOS/tvOS share the same codebase but are not yet published; requires Xcode to build locally.

## Gotchas

- `POSTGRES_PASSWORD` must be **identical** in both the `hound-postgres` environment block and the `hound-server` environment block — mismatches cause silent connection failures
- Default admin password is `password` — change it on first login
- External Library mounts follow a specific path convention (`/app/External Library/Movies`, `/app/External Library/TV Shows`) — read the [library docs](https://hound-media-server.github.io/hound-site/library.html) before mounting
- Transcoding is not yet implemented; streams served as-is — client must be able to play the source codec
- Project under active development; pin a specific image tag in production once a stable release is available
