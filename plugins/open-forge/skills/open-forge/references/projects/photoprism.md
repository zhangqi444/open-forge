---
name: photoprism-project
description: PhotoPrism recipe for open-forge. AGPL-3.0 AI-powered photo app — import, browse, face-recognize, tag, and geocode your photos/videos. Go + TensorFlow + MariaDB/MySQL + Caddy/nginx. Ships as `photoprism/photoprism` multi-arch image with canonical docker-compose at the official getting-started page. Covers Community Edition self-host, the TensorFlow vs non-TensorFlow split, Raspberry Pi considerations, WebDAV endpoint, and the important admin-user env-var semantics.
---

# PhotoPrism

AGPL-3.0 AI-powered photos app. Browse, search, tag, face-recognize, and geocode a personal photo+video library. Upstream: <https://github.com/photoprism/photoprism>. Docs: <https://docs.photoprism.app/>. Demo: <https://try.photoprism.app/>.

Key components:

- Go backend serving the web UI + REST API + WebDAV (port 2342 internally)
- TensorFlow models for label / face / NSFW classification (optional — disable for low-RAM hosts)
- MariaDB (recommended) or MySQL 8+ as metadata DB
- SQLite for tiny installs (upstream's lower-tier fallback — not recommended for >10k photos)

**Two "Editions"** per upstream:

- **Community Edition (CE)** — AGPL-3.0, this recipe's target. Full feature set for personal use.
- **Teams / Commercial** — paid plans with extra web features (interactive world maps, priority support). Uses the same Docker image; enables features via membership activation. See <https://www.photoprism.app/membership>.

Both run the same binary. This recipe covers CE self-host on your hardware.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.photoprism.app/getting-started/docker-compose/> | ✅ Recommended | Upstream's canonical install. Most deployments. |
| `docker run` | <https://docs.photoprism.app/getting-started/docker/> | ✅ | Quick tests. Prefer Compose. |
| Raspberry Pi | <https://docs.photoprism.app/getting-started/raspberry-pi/> | ✅ | Pi 4/5 with 4GB+ RAM. Multi-arch image works; disable TensorFlow for lower RAM. |
| `.tar.gz` packages (Linux) | <https://dl.photoprism.app/pkg/linux/README.html> | ✅ | Bare-metal install without Docker. |
| macOS desktop app | <https://docs.photoprism.app/getting-started/mac/> | ✅ | Gatekeeper-signed PKG bundling PhotoPrism + MariaDB. |
| Windows desktop app | <https://docs.photoprism.app/getting-started/windows/> | ✅ | Installer bundling PhotoPrism + MariaDB on Windows 10+. |
| Proxmox LXC / TrueNAS / Unraid | Community | ⚠️ | Popular on selfh.st; not upstream-maintained. |
| Kubernetes | Community | ⚠️ | No official Helm chart; community charts drift. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `docker-run` / `pi` / `tar.gz` / `mac` / `windows` | Drives section. |
| preflight | "Disable TensorFlow? (for low-RAM hosts, e.g. Pi / 2GB VPS)" | Boolean | `PHOTOPRISM_DISABLE_TENSORFLOW=true` reclaims ~1GB RAM at the cost of labels + face recognition. |
| storage | "Originals path?" | Free-text (e.g. `~/Pictures`) | Mounted read-write at `/photoprism/originals`. **This is the source of truth for your library.** |
| storage | "Storage path?" (for cache / sidecar / DB) | Free-text, default `./storage` | Mounted at `/photoprism/storage`. Contains thumbnails, DB (if SQLite), sidecars. |
| storage | "Separate import path?" (optional one-way ingest folder) | Free-text | Mounted at `/photoprism/import`. Files moved OUT of here and into originals on import. |
| admin | "Admin username + password?" | Free-text (sensitive) | `PHOTOPRISM_ADMIN_USER` + `PHOTOPRISM_ADMIN_PASSWORD`. Password min 8 chars (upstream enforces). |
| dns | "Public URL?" | Free-text | `PHOTOPRISM_SITE_URL=https://photos.example.com/`. Trailing slash matters. |
| tls | "TLS strategy?" | `AskUserQuestion`: `reverse-proxy (Caddy/nginx/Traefik)` / `built-in HTTPS via PHOTOPRISM_INIT=https` / `skip (LAN only)` | Built-in HTTPS uses self-signed certs — browsers will warn. Reverse proxy with Let's Encrypt is standard. |
| db | "DB backend?" | `AskUserQuestion`: `MariaDB (recommended)` / `MySQL 8+` / `SQLite (tiny installs)` | MariaDB is upstream's default; SQLite loses features like soft-delete recovery. |
| uid-gid | "PUID/PGID?" | Free-text, default `1000:1000` | Set to your host user's `id -u`/`id -g` so originals + imports are writable. |

## Install — Docker Compose (upstream-recommended)

Upstream's canonical compose lives at <https://docs.photoprism.app/getting-started/docker-compose/>. The key services:

```yaml
services:
  photoprism:
    image: photoprism/photoprism:latest
    container_name: photoprism
    restart: unless-stopped
    stop_grace_period: 10s
    depends_on:
      - mariadb
    security_opt:
      - seccomp:unconfined
      - apparmor:unconfined
    ports:
      - "2342:2342"
    environment:
      PHOTOPRISM_ADMIN_USER: "admin"
      PHOTOPRISM_ADMIN_PASSWORD: "<strong-password>"
      PHOTOPRISM_AUTH_MODE: "password"
      PHOTOPRISM_SITE_URL: "http://photos.example.com/"
      PHOTOPRISM_ORIGINALS_LIMIT: 5000              # per-file size cap MB
      PHOTOPRISM_HTTP_COMPRESSION: "gzip"
      PHOTOPRISM_LOG_LEVEL: "info"
      PHOTOPRISM_READONLY: "false"
      PHOTOPRISM_EXPERIMENTAL: "false"
      PHOTOPRISM_DISABLE_CHOWN: "false"
      PHOTOPRISM_DISABLE_WEBDAV: "false"
      PHOTOPRISM_DISABLE_SETTINGS: "false"
      PHOTOPRISM_DISABLE_TENSORFLOW: "false"        # set "true" to save ~1GB RAM
      PHOTOPRISM_DISABLE_FACES: "false"
      PHOTOPRISM_DISABLE_CLASSIFICATION: "false"
      PHOTOPRISM_DATABASE_DRIVER: "mysql"
      PHOTOPRISM_DATABASE_SERVER: "mariadb:3306"
      PHOTOPRISM_DATABASE_NAME: "photoprism"
      PHOTOPRISM_DATABASE_USER: "photoprism"
      PHOTOPRISM_DATABASE_PASSWORD: "<db-password>"
      PHOTOPRISM_SITE_CAPTION: "AI-Powered Photos App"
      PHOTOPRISM_SITE_DESCRIPTION: ""
      PHOTOPRISM_SITE_AUTHOR: ""
      PHOTOPRISM_UID: 1000
      PHOTOPRISM_GID: 1000
    working_dir: "/photoprism"
    volumes:
      - "~/Pictures:/photoprism/originals"          # YOUR library (source of truth)
      - "./import:/photoprism/import"               # optional one-way ingest
      - "./storage:/photoprism/storage"             # cache, sidecars, config

  mariadb:
    image: mariadb:11
    container_name: photoprism-mariadb
    restart: unless-stopped
    stop_grace_period: 5s
    security_opt:
      - seccomp:unconfined
      - apparmor:unconfined
    command: mysqld --innodb-buffer-pool-size=512M --transaction-isolation=READ-COMMITTED --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --max-connections=512 --innodb-rollback-on-timeout=OFF --innodb-lock-wait-timeout=120
    volumes:
      - "./database:/var/lib/mysql"
    environment:
      MARIADB_AUTO_UPGRADE: "1"
      MARIADB_INITDB_SKIP_TZINFO: "1"
      MARIADB_DATABASE: "photoprism"
      MARIADB_USER: "photoprism"
      MARIADB_PASSWORD: "<db-password>"
      MARIADB_ROOT_PASSWORD: "<root-password>"
```

```bash
mkdir -p photoprism/{storage,import,database}
cd photoprism
# write docker-compose.yml as above
docker compose up -d
docker compose logs -f photoprism
```

Visit `http://<host>:2342/` and log in with the admin credentials set in env.

### Reverse proxy (Caddy)

```caddy
photos.example.com {
    reverse_proxy localhost:2342
}
```

Set `PHOTOPRISM_SITE_URL=https://photos.example.com/` (trailing slash required) in the compose so absolute URLs + OAuth callbacks work.

## Install — Raspberry Pi

Upstream officially supports Pi 4 (4GB+) and Pi 5. Same Docker image; specific tuning:

```yaml
environment:
  PHOTOPRISM_DISABLE_TENSORFLOW: "true"    # Required on <4GB Pis; optional on 8GB
  PHOTOPRISM_DISABLE_CLASSIFICATION: "true"
  PHOTOPRISM_DISABLE_FACES: "true"
  PHOTOPRISM_ORIGINALS_LIMIT: 1000         # limit per-file size on slow storage
```

External USB SSD for `originals` + `storage` is ~mandatory; SD cards are too slow + wear out fast with thumbnail generation.

Full Pi guide: <https://docs.photoprism.app/getting-started/raspberry-pi/>.

## Install — `.tar.gz` bare metal

```bash
# Linux amd64 example
cd /tmp
curl -O https://dl.photoprism.app/pkg/linux/amd64.tar.gz
tar -xzf amd64.tar.gz -C /opt/
export PATH=/opt/photoprism/bin:$PATH
photoprism --help
```

You'll also need MariaDB/MySQL installed separately + TensorFlow C library. See <https://dl.photoprism.app/pkg/linux/README.html>. Most users find Docker significantly easier.

## First-run workflow

1. Log in with the admin credentials from env.
2. **Settings → Library → Start** triggers initial indexing of `/photoprism/originals`.
3. Indexing can take hours for large libraries (CPU: OCR + face + label extraction). Watch `docker compose logs -f photoprism`.
4. After first index, labels/people/places should appear in the UI.
5. Set up WebDAV / backup / sharing as needed.

## WebDAV endpoint

PhotoPrism exposes WebDAV at `/originals/` and `/import/`. Useful for clients (Finder, Windows Explorer, PhotoSync iOS app) to push photos directly:

- URL: `https://photos.example.com/originals/`
- Credentials: your PhotoPrism user account
- See <https://docs.photoprism.app/user-guide/sync/webdav/>

Set `PHOTOPRISM_DISABLE_WEBDAV=true` to turn it off if you don't use it.

## Backup

The canonical backup:

1. **MariaDB dump** — `docker compose exec -T mariadb mysqldump -u root -p"$ROOT_PW" photoprism > photoprism-db-$(date +%F).sql`
2. **Originals** — backed up separately (they're YOUR source library; should already be on durable storage).
3. **Storage** — thumbnails and sidecars are rebuilt from originals + DB, so optional; but `storage/sidecar/` contains XMP/YAML metadata that took compute to generate, worth preserving.

Upstream also ships `photoprism backup` command:

```bash
docker compose exec photoprism photoprism backup -a
# writes YAML per-album backups under /photoprism/storage/backup/
```

This is an incremental export of album structure + metadata, not a full DB dump — use alongside the mysqldump, not instead.

## Upgrade procedure

```bash
# 1. Dump DB + snapshot storage/
docker compose exec -T mariadb mysqldump -u root -p"$ROOT_PW" photoprism > photoprism-db-$(date +%F).sql

# 2. Read release notes
# https://docs.photoprism.app/release-notes/

# 3. Pull new image + restart
docker compose pull
docker compose up -d
docker compose logs -f photoprism
```

DB migrations run automatically on boot. Upstream maintains strict backwards-compat for the DB schema — downgrade is usually safe within the same major version.

For **major version** bumps (rare — PhotoPrism moves slowly), read the release notes carefully; MariaDB buffer-pool and index rebuild may be needed.

## Key environment variables

Full reference: <https://docs.photoprism.app/getting-started/config-options/>.

| Var | Default | Purpose |
|---|---|---|
| `PHOTOPRISM_ADMIN_USER` / `PHOTOPRISM_ADMIN_PASSWORD` | | Bootstrap admin. Re-applies if user doesn't exist. |
| `PHOTOPRISM_AUTH_MODE` | `password` | `public` = no auth (dangerous), `password` = normal. |
| `PHOTOPRISM_SITE_URL` | | Public URL with trailing slash — required behind reverse proxy. |
| `PHOTOPRISM_DATABASE_DRIVER` / `…_SERVER` / `…_NAME` / `…_USER` / `…_PASSWORD` | | DB connection. |
| `PHOTOPRISM_DISABLE_TENSORFLOW` | `false` | Set `true` on low-RAM hosts (<4GB). |
| `PHOTOPRISM_DISABLE_FACES` / `…_CLASSIFICATION` / `…_NSFW` | `false` | Fine-grained disable of TensorFlow features. |
| `PHOTOPRISM_DISABLE_WEBDAV` | `false` | Turn off WebDAV endpoint. |
| `PHOTOPRISM_READONLY` | `false` | Library read-only; disables edit/delete/upload. |
| `PHOTOPRISM_UPLOAD_NSFW` | `false` | Block NSFW uploads if `false`. |
| `PHOTOPRISM_ORIGINALS_LIMIT` | `1000` | Per-file size limit in MB. |
| `PHOTOPRISM_HTTP_PORT` / `PHOTOPRISM_HTTP_HOST` | `2342` / `0.0.0.0` | Bind address. |
| `PHOTOPRISM_DISABLE_CHOWN` | `false` | If `false`, PhotoPrism chowns `/photoprism/storage` on boot to PUID:PGID. |
| `PHOTOPRISM_INIT` | | Space-separated init directives, e.g. `https tensorflow`. |
| `PHOTOPRISM_UID` / `PHOTOPRISM_GID` | `1000` | Run-as user/group. Match host for bind-mount writability. |

## Gotchas

- **`originals` is your source of truth.** Treat that path like you would any photo library — back it up elsewhere. PhotoPrism will happily "Edit Metadata → Write to Files" which modifies the originals in place.
- **PHOTOPRISM_UID / PHOTOPRISM_GID mismatches silently break uploads.** If the container runs as 1000:1000 but your host user is 1001, uploads from the web UI succeed but the files are owned by an inaccessible uid. Verify by checking `ls -la` after first upload.
- **TensorFlow is a 1GB+ resident memory hog.** On <4GB hosts, disable it. Re-enabling later requires re-indexing to generate labels/faces for existing photos.
- **MariaDB `innodb-buffer-pool-size=512M` in the default compose is a FLOOR, not a ceiling.** Small libraries waste this; huge libraries need much more. Tune to roughly 25% of host RAM up to ~4GB.
- **`auto_upgrade` on MariaDB is a safety net, not a strategy.** The compose sets `MARIADB_AUTO_UPGRADE=1` which handles minor version bumps. Major version bumps (MariaDB 10 → 11) can still need manual `mysql_upgrade`.
- **First index is CPU-heavy.** On 2 cores, expect 5–10k photos/hour for TensorFlow+OCR. Let it finish — partial indexes have empty labels. `PHOTOPRISM_WORKERS` tunes concurrency.
- **Thumbnails balloon `storage/`.** Budget roughly 5% of `originals` size for `storage/cache/`. `PHOTOPRISM_THUMB_SIZE` (default 1920) controls max pre-rendered size; 4K displays look better with `4096` but storage cost doubles.
- **Private/NSFW detection is on by default but useless without TensorFlow.** If you disabled TF, photos won't be auto-flagged — the "Private" album is manual only.
- **Originals path change = full re-index.** Moving photos between mounted directories forces PhotoPrism to re-hash everything. Plan the mount layout carefully before first index.
- **Apparmor/seccomp unconfined is in the default compose.** Some TensorFlow ops trip the default seccomp profile. If your threat model forbids this, you'll need a custom seccomp profile rather than removing the flags outright (expect random AI feature failures).
- **AUTH_MODE=public means no login.** Never set this on an internet-exposed instance — anyone can browse and download your full library.
- **Video transcoding is CPU-heavy.** Ffmpeg transcode of unsupported codecs happens on first play of a video. For big libraries with many AVIs / MKVs, pre-transcode or keep originals in web-friendly H.264.
- **No Helm chart.** Kubernetes deploys are community-only and often behind on versions. Docker Compose is the supported shape.
- **Teams/Commercial features are opt-in via membership activation.** CE is fully functional for personal use — you don't "need" to buy a license. Maps/places currently require a (free) membership for full functionality per upstream's Places service.

## Links

- Upstream repo: <https://github.com/photoprism/photoprism>
- Docs: <https://docs.photoprism.app/>
- Getting started: <https://docs.photoprism.app/getting-started/>
- Docker Compose guide: <https://docs.photoprism.app/getting-started/docker-compose/>
- Config options: <https://docs.photoprism.app/getting-started/config-options/>
- Raspberry Pi: <https://docs.photoprism.app/getting-started/raspberry-pi/>
- `.tar.gz` packages: <https://dl.photoprism.app/pkg/linux/README.html>
- WebDAV: <https://docs.photoprism.app/user-guide/sync/webdav/>
- Release notes: <https://docs.photoprism.app/release-notes/>
- Discussions: <https://github.com/photoprism/photoprism/discussions>
