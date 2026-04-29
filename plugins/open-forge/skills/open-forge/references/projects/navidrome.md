---
name: Navidrome
description: Modern web-based music server and streamer. Subsonic/Madsonic/Airsonic API compatible, single Go binary, low resource usage.
---

# Navidrome

Navidrome is a self-hosted music streaming server. Point it at a folder of music; it indexes tags, artwork, and playlists, and exposes a web UI plus the Subsonic API — which means all existing Subsonic client apps (iOS/Android/desktop) work unchanged.

- Upstream repo: <https://github.com/navidrome/navidrome>
- Project site: <https://www.navidrome.org/>
- Docs: <https://www.navidrome.org/docs/>
- Image: `deluan/navidrome` (Docker Hub), `ghcr.io/navidrome/navidrome`

## Compatible install methods

| Infra           | Runtime                                     | Notes                                                                |
| --------------- | ------------------------------------------- | -------------------------------------------------------------------- |
| Single VM       | Docker + Compose                            | Recommended; upstream ships `contrib/docker-compose/docker-compose.yml` |
| Single VM       | Systemd + pre-built binary                  | Well-supported; binaries at <https://github.com/navidrome/navidrome/releases> |
| Single VM       | Docker + Traefik / Caddy overlay            | Upstream ships ready-made compose files for both                     |
| Raspberry Pi    | ARM64/ARMv7 Docker image or binary          | Official support                                                     |
| Kubernetes      | Helm chart (community)                      | Not upstream-official                                                |
| PikaPods (SaaS) | Managed hosting                             | Upstream-endorsed partnership                                        |

## Inputs to collect

| Input                           | Example                          | Phase   | Notes                                                                |
| ------------------------------- | -------------------------------- | ------- | -------------------------------------------------------------------- |
| Music library path              | `/mnt/music`                     | Host    | Read-only bind-mount recommended                                     |
| Data dir                        | Docker volume `navidrome_data`   | Runtime | Holds SQLite DB, cache, artwork thumbs                               |
| Listen port                     | `4533`                           | Runtime | Default; change with `-p HOST:4533`                                   |
| UID:GID                         | `1000:1000`                      | Runtime | Match owner of music library for correct file access                 |
| `ND_BASEURL` (optional)         | `/music`                         | Runtime | Set if reverse-proxied under a sub-path                              |
| `ND_SCANSCHEDULE` (optional)    | `@every 1h`                      | Runtime | Cron-ish format; default is every minute                             |
| Reverse proxy + TLS             | Caddy/nginx/Traefik              | Network | Navidrome serves plain HTTP; terminate TLS upstream                 |

## Install via Docker Compose

Upstream's canonical minimal compose (<https://github.com/navidrome/navidrome/blob/master/contrib/docker-compose/docker-compose.yml>):

```yaml
services:
  navidrome:
    container_name: navidrome
    image: deluan/navidrome:0.55.2      # pin; https://github.com/navidrome/navidrome/releases
    restart: unless-stopped
    read_only: true
    user: "1000:1000"                   # match host owner of music + data dirs
    ports:
      - "4533:4533"
    volumes:
      - "navidrome_data:/data"
      - "/mnt/music:/music:ro"          # read-only mount of your library
    environment:
      - ND_LOGLEVEL=info
      # - ND_BASEURL=/music             # uncomment if reverse-proxied under a sub-path
      # - ND_SCANSCHEDULE=@every 1h
      # - ND_SESSIONTIMEOUT=24h

volumes:
  navidrome_data:
```

```sh
docker compose up -d
# Browse http://<host>:4533 → create the first account (becomes admin)
# First full scan kicks off automatically; monitor /data/navidrome.db-wal growth
```

### Traefik / Caddy variants

Upstream ships ready-to-use compose overlays:

- Caddy: <https://github.com/navidrome/navidrome/blob/master/contrib/docker-compose/docker-compose-caddy.yml>
- Traefik: <https://github.com/navidrome/navidrome/blob/master/contrib/docker-compose/docker-compose-traefik.yml>

## Data & config layout

- `/data/navidrome.db` — SQLite database (library metadata, users, playlists, favorites)
- `/data/cache/` — transcoded audio + artwork thumbnails
- `/music/` — your library (mounted **read-only**; Navidrome does not write here)
- No persistent config file required; everything via `ND_*` env vars. Optional `/data/navidrome.toml` is supported but rarely needed.

Full env var reference: <https://www.navidrome.org/docs/usage/configuration-options/>

## Backup

The SQLite DB is tiny (MBs even for huge libraries). Back up the whole `/data` volume:

```sh
docker compose stop navidrome   # quiesce SQLite writers
docker run --rm -v compose_navidrome_data:/data -v "$PWD":/backup alpine \
  tar czf /backup/navidrome-$(date +%F).tgz -C /data .
docker compose start navidrome
```

Or use SQLite's online-backup while running:

```sh
docker compose exec navidrome sqlite3 /data/navidrome.db ".backup '/data/backup.db'"
```

You don't need to back up your music library via Navidrome — it's on disk already and read-only from Navidrome's perspective.

## Upgrade

1. Check <https://github.com/navidrome/navidrome/releases> for schema/config changes.
2. Bump the `image:` tag in compose.
3. `docker compose pull && docker compose up -d`.
4. Navidrome auto-applies SQLite migrations on startup; first run after a major may re-scan the library.

Releases are frequent; SemVer is loose (0.x.y) — read release notes for any tag jump.

## Gotchas

- **`read_only: true` + UID mapping.** The upstream compose runs with a read-only root FS and expects all writes to go through `/data`. If you add a container-side config file or plugin dir, mount it explicitly or drop `read_only`.
- **First scan is slow** for large libraries (~10k+ tracks). Watch progress in logs or the UI admin panel; don't interrupt it.
- **Subsonic clients use HTTP Basic-style auth over plain HTTP** unless you put Navidrome behind TLS. Always terminate TLS at the reverse proxy, especially for password-exposed Subsonic apps.
- **Transcoding needs `ffmpeg`** — bundled in the Docker image, not in the bare binary. If you install via pre-built binary, install ffmpeg separately.
- **`ND_BASEURL` is sticky.** Change it only when moving between reverse-proxy path configs; existing client sessions may need re-login.
- **SQLite + shared network mount** (NFS/SMB for `/data`) is a hazard; keep `/data` on local disk even if the music library is networked.
- **ARM32v7** images are slower at scan/transcode than ARM64 — for Raspberry Pi 4/5, use `arm64` image.
- **Playlists from m3u files** in the library are imported read-only. To edit playlists from the Navidrome UI, they become "managed" playlists stored in the DB, detached from the m3u.
- **Do not expose port 4533 directly to the internet** without TLS + auth-tight reverse proxy. Subsonic API has brute-force resistance but isn't a hardened public endpoint.
- **First user auto-admins.** Disable open registration via admin UI once the first user is created; no env-var kill switch.
- **Last.fm / ListenBrainz scrobbling** needs `ND_LASTFM_APIKEY` + secret or `ND_LISTENBRAINZ_ENABLED=true`. Offline by default.

## Links

- Repo: <https://github.com/navidrome/navidrome>
- Docs: <https://www.navidrome.org/docs/>
- Installation: <https://www.navidrome.org/docs/installation/>
- Docker install: <https://www.navidrome.org/docs/installation/docker/>
- Configuration options: <https://www.navidrome.org/docs/usage/configuration-options/>
- Releases: <https://github.com/navidrome/navidrome/releases>
- Subsonic-compatible clients: <https://www.navidrome.org/docs/overview/#apps>
- Docker Hub: <https://hub.docker.com/r/deluan/navidrome>
