---
name: Koel
description: Simple web-based personal audio-streaming server. PHP (Laravel) + Vue SPA. Plays music from a local directory or S3. MIT-licensed.
---

# Koel

Koel serves your personal music library over a Spotify-style web UI. It scans a music directory (or S3 bucket), reads ID3 tags via `getID3`, and streams FLAC/MP3/etc. to a Vue SPA. Supports playlists, smart playlists, favorites, YouTube search-and-play, last.fm scrobbling, multi-user, and (paid Plus) podcasts + mobile apps.

- Upstream repo: <https://github.com/koel/koel>
- Docker repo: <https://github.com/koel/docker>
- Docs: <https://docs.koel.dev/>
- Image: `phanan/koel` on Docker Hub

## Architecture in one minute

- **Koel image** (`phanan/koel`) — Apache + PHP 8.x + compiled front-end assets. No built-in database.
- **External database** — MariaDB/MySQL or PostgreSQL, in a sibling container.
- **Library location** — mount your music at `/music` inside the Koel container.
- **`APP_KEY`** — Laravel encryption key; generated on first `koel:init` and must be persisted across container recreates.

## Compatible install methods

| Infra              | Runtime            | Notes                                                                        |
| ------------------ | ------------------ | ---------------------------------------------------------------------------- |
| Single VM          | Docker Compose     | **Recommended.** Upstream `koel/docker` ships two ready compose files         |
| Bare metal         | PHP + Composer + Node + Yarn | Possible but fiddly; docs at <https://docs.koel.dev/installation>    |
| Kubernetes         | Custom manifests   | Works; no upstream chart                                                     |

## Inputs to collect

| Input           | Example                         | Phase    | Notes                                                                      |
| --------------- | ------------------------------- | -------- | -------------------------------------------------------------------------- |
| `APP_KEY`       | 32-byte random, base64          | Runtime  | **Persist or bind-mount `.env`.** Losing the key = can't decrypt user data  |
| DB backend      | MariaDB 10.11 / Postgres 16     | Runtime  | Upstream ships two compose templates; pick one                             |
| DB credentials  | `koel` / strong password        | Runtime  | Not the default `<koel_password>` literal from the template                 |
| Music dir       | `/srv/music` (host) → `/music`  | Data     | Read-only mount recommended                                                |
| Admin login     | `admin@koel.dev` / `KoelIsCool` | **SECURITY** | **Default admin is hard-coded in the image.** Change immediately          |
| Port            | `80:80` (or behind reverse proxy) | Network | No built-in TLS                                                             |
| AWS S3 (optional) | bucket + keys                 | Runtime  | Alternative to local `/music`; uses presigned URLs for streaming            |

## Install via Docker Compose (MariaDB)

From <https://github.com/koel/docker/blob/master/docker-compose.mysql.yml> (values templated with placeholders; replace them):

```yaml
services:
  koel:
    image: phanan/koel:v8.3.1          # pin; never rely on :latest in prod
    depends_on:
      - database
    ports:
      - 80:80
    environment:
      - DB_CONNECTION=mysql
      - DB_HOST=database
      - DB_USERNAME=koel
      - DB_PASSWORD=REPLACE_WITH_STRONG_PASSWORD
      - DB_DATABASE=koel
      - APP_KEY=base64:REPLACE_WITH_GENERATED_KEY
    volumes:
      - ./music:/music:ro              # your library, read-only
      - image_storage:/var/www/html/public/img/storage
      - search_index:/var/www/html/storage/search-indexes

  database:
    image: mariadb:10.11
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=REPLACE_ME
      - MYSQL_DATABASE=koel
      - MYSQL_USER=koel
      - MYSQL_PASSWORD=REPLACE_WITH_STRONG_PASSWORD

volumes:
  db:
  image_storage:
  search_index:
```

### Generate `APP_KEY` before first run

```sh
docker run --rm phanan/koel:v8.3.1 php artisan key:generate --show
# output: base64:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
```

Paste the value into `APP_KEY=`. **If you don't, `koel:init` generates one inside the container — but it lives in a non-persisted `.env` and disappears on `docker compose down -v`.**

## First-run & admin password change

On first boot the entrypoint runs `koel:init` which:

1. Waits for the database
2. Runs Laravel migrations
3. Creates the default admin `admin@koel.dev` / `KoelIsCool`
4. Scans `/music`

**Change the admin password immediately:**

```sh
docker exec -it <koel_container> php artisan koel:admin:change-password
```

Disable the init on subsequent runs with `SKIP_INIT=true` if you're doing your own migrations/seeds.

## Scanning new music

Koel doesn't auto-watch `/music`. After adding files, trigger a rescan:

```sh
docker exec -it <koel_container> php artisan koel:scan
# or, inside the UI: Admin → Settings → Rescan
```

Large libraries (10k+ tracks) can take minutes. `--no-progress` helps for scripted rescans.

## Data & config layout

Inside the container:

- `/var/www/html/.env` — generated config (persist this or `APP_KEY` via env)
- `/var/www/html/public/img/storage` — album artwork / playlist covers
- `/var/www/html/storage/search-indexes` — Scout/Meilisearch index (if enabled)
- `/music` — your library (host-mounted)

Database volume holds users, tracks metadata, playlists, play counts. Music files are never written by Koel (you mount `:ro`).

## Backup

```sh
# Database
docker compose exec -T database mysqldump -u root -p"$ROOT_PWD" koel | gzip > koel-db-$(date +%F).sql.gz

# Image storage + search index
for v in image_storage search_index; do
  docker run --rm -v "${v}":/src -v "$PWD":/backup alpine tar czf "/backup/${v}-$(date +%F).tgz" -C /src .
done

# Music files: back up from the host source, not the Koel volume
```

## Upgrade

1. Releases: <https://github.com/koel/koel/releases>.
2. Bump image tag (read the release notes — Koel has shipped schema-breaking changes between majors).
3. `docker compose pull && docker compose up -d`.
4. Container entrypoint re-runs `koel:init`; migrations apply automatically unless `SKIP_INIT=true`.
5. For manual migrations: `docker exec -it <koel> php artisan migrate --force`.
6. `master` branch docs may document features not in your tag — switch to the tag on GitHub for accurate docs: `https://github.com/koel/docker/tree/v8.3.1`.

## Gotchas

- **Default admin is public knowledge** (`admin@koel.dev` / `KoelIsCool`). First login, immediately rotate. Koel has no "force password change on first login" flag.
- **`APP_KEY` loss = data loss.** Without the original key, Laravel can't decrypt stored user settings / tokens. Back up your `.env` or pass `APP_KEY` as an env var from day one.
- **No built-in HTTPS.** Run behind Caddy/Traefik/nginx-proxy for TLS; set `APP_URL=https://koel.example.com` in env so generated asset URLs match.
- **Library is read-only from Koel's perspective** — Koel never rewrites your tag data. Tag editing via the UI requires Koel Plus (paid).
- **Streaming method matters.** Default `STREAMING_METHOD=php` streams through PHP — fine for small installs, slow for many concurrent users. Alternatives: `x-sendfile` (Apache) or `x-accel-redirect` (nginx). Docs: <https://docs.koel.dev/media-streaming>.
- **S3 support exists** (`S3_HOST`, `S3_BUCKET`, `S3_KEY`, `S3_SECRET`) but is a commercial-tier feature on some forks — check the env reference for your version.
- **Search index rebuilds on every `koel:scan`** unless you're using Meilisearch/Algolia. Persist `search-indexes` volume to avoid pathological re-scans.
- **YouTube integration** requires a Google API key; `YOUTUBE_API_KEY` env var. Without it, the YouTube sidebar is inert.
- **last.fm scrobbling** needs `LASTFM_API_KEY` + `LASTFM_API_SECRET` at deploy time — setting them later requires a container restart.
- **`docker-compose.postgres.yml`** exists as an alternative; it uses `postgres:16-alpine`. Don't mix — pick one and stick with it; migrating between DBs means dumping/re-importing.
- **Koel is maintained by one person** (Phan An). Response time on issues varies. Plus (paid) funds development.
- **PHP 8.x** minimum. The `phanan/koel` image bundles PHP — you don't install it — but if you run bare-metal, get the version right.
- **Mobile apps, Last.fm, podcasts, AirPlay, Plus-only features** require a paid license key: <https://koel.dev/plus>. Community edition is fully functional for streaming + playlists.

## Links

- Main repo: <https://github.com/koel/koel>
- Docker repo + compose templates: <https://github.com/koel/docker>
- Docs: <https://docs.koel.dev/>
- Installation docs: <https://docs.koel.dev/installation>
- Env reference (`.env.example`): <https://github.com/koel/koel/blob/master/.env.example>
- Releases: <https://github.com/koel/koel/releases>
- Koel Plus (commercial features): <https://koel.dev/plus>
- Docker Hub: <https://hub.docker.com/r/phanan/koel>
