---
name: paperless-ngx-project
description: Paperless-ngx recipe for open-forge. GPL-3.0 document management system — scan / import / OCR / index / tag / full-text-search your paper documents. Django backend + Angular frontend + PostgreSQL + Redis + Tika + Gotenberg. Covers the upstream install script (`install-paperless-ngx.sh`), the 4 docker-compose variants (postgres/sqlite × with-or-without-tika), bare-metal install, and the critical "DO NOT EXPOSE TO UNTRUSTED NETWORK" warning from upstream — sensitive documents are stored unencrypted.
---

# Paperless-ngx

GPL-3.0 document management system. Takes in PDFs/images/office docs via a "consume" folder or upload UI, runs OCR, extracts metadata, assigns tags/correspondents/types, indexes for full-text search. Upstream: <https://github.com/paperless-ngx/paperless-ngx>. Docs: <https://docs.paperless-ngx.com/>. Demo: <https://demo.paperless-ngx.com/> (`demo` / `demo`).

Successor to the original Paperless (archived) and Paperless-ng (archived). Actively maintained by a volunteer team.

**⚠️ Security posture (from upstream README):** *"Document scanners are typically used to scan sensitive documents… Paperless-ngx should never be run on an untrusted host because information is stored in clear text without encryption. The safest way to run Paperless-ngx is on a local server in your own home with backups in place."* Treat this as LAN-first software. A VPS deploy is fine if locked behind Tailscale/WireGuard + strong auth.

## Stack shape

The upstream compose assembles ~5 services:

- **webserver** — Django + Angular (port 8000)
- **broker** — Redis (queue)
- **db** — PostgreSQL (or skip if using SQLite variant)
- **gotenberg** (optional) — Office doc → PDF converter (port 3000)
- **tika** (optional) — Apache Tika for metadata + content extraction from Office docs

Without Gotenberg/Tika, Paperless processes PDFs and images only. Add them if you ingest `.docx` / `.xlsx` / email attachments.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `install-paperless-ngx.sh` (interactive bootstrap) | <https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/install-paperless-ngx.sh> | ✅ Recommended | Prompts for passwords / paths / variant, generates compose + env files. |
| Docker Compose (manual) | <https://github.com/paperless-ngx/paperless-ngx/tree/main/docker/compose> | ✅ | When you want to pre-configure before first boot. 4 variants: `postgres`, `postgres-tika`, `sqlite`, `sqlite-tika`. |
| Bare metal | <https://docs.paperless-ngx.com/setup/#installation> | ✅ | Python 3.10+ / Node.js / PostgreSQL-or-SQLite / Redis on host. Rarely chosen — Docker is easier. |
| Kubernetes | Community Helm charts | ⚠️ Community | <https://github.com/paperless-ngx/paperless-ngx/tree/main/k8s> has examples but not a maintained chart. |
| Proxmox LXC / TrueNAS / Unraid | Community | ⚠️ Community | Popular on selfh.st; third-party scripts like tteck's Proxmox helper scripts. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `install.sh` / `compose-manual` / `bare-metal` | Drives section. |
| preflight | "DB backend?" | `AskUserQuestion`: `PostgreSQL (recommended)` / `MariaDB` / `SQLite (small installs only)` | PostgreSQL is upstream's default; SQLite is supported but not recommended for >10k documents. |
| preflight | "Install Gotenberg + Tika?" | Boolean | Needed for Office doc ingestion. |
| network | "LAN-only or public?" | `AskUserQuestion` | Drives warnings about exposure. |
| network | "Public domain?" | Free-text | Only if public. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `Caddy` / `nginx` / `Traefik` / `skip` | Paperless does not terminate TLS itself. |
| admin | "Admin username / password / email?" | Free-text (sensitive) | Set via `PAPERLESS_ADMIN_USER` / `PAPERLESS_ADMIN_PASSWORD` / `PAPERLESS_ADMIN_MAIL` env — only takes effect if no users exist yet. |
| storage | "Host paths for `data`, `media`, `consume`, `export`?" | Free-text | Either named volumes (default) or bind-mounts to host paths. Bind-mount `consume/` to where your scanner drops files. |
| secrets | "Django secret key?" | Auto-generate (`openssl rand -hex 32`) → `PAPERLESS_SECRET_KEY` | Critical — don't commit to git. |
| ocr | "OCR languages?" (e.g. `eng`, `deu+eng`, `fra`) | Free-text | `PAPERLESS_OCR_LANGUAGE`. Space to install extra Tesseract language packs. |
| timezone | "TZ?" (e.g. `America/Los_Angeles`) | Free-text | `PAPERLESS_TIME_ZONE`. Affects document dates. |

## Install — install-paperless-ngx.sh (upstream bootstrap)

```bash
# Review the script first — https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/install-paperless-ngx.sh
bash -c "$(curl -L https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/install-paperless-ngx.sh)"
```

Interactive prompts cover:

- Target directory (default `~/paperless-ngx`)
- URL the install will be served at
- Port mapping
- PostgreSQL vs SQLite; Tika yes/no
- OCR languages (Tesseract lang packs to install inside the webserver image)
- Timezone
- Admin user/password/email
- Optional: a user ID / group ID for bind-mount ownership

The script writes `docker-compose.yml` + `docker-compose.env` + `.env` into the target dir, then runs `docker compose up -d`.

## Install — Docker Compose (manual)

Upstream ships 4 compose variants under `docker/compose/`:

| File | DB | Tika? | Use when |
|---|---|---|---|
| `docker-compose.postgres.yml` | PostgreSQL | No | Default for small-medium installs. |
| `docker-compose.postgres-tika.yml` | PostgreSQL | Yes | Office doc ingestion. Upstream's recommended production shape. |
| `docker-compose.sqlite.yml` | SQLite | No | Pi / tiny installs. <10k documents. |
| `docker-compose.sqlite-tika.yml` | SQLite | Yes | Same + Office docs. |

```bash
mkdir -p ~/paperless && cd ~/paperless
# Grab the variant you want:
curl -O https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/docker/compose/docker-compose.postgres-tika.yml
mv docker-compose.postgres-tika.yml docker-compose.yml
curl -O https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/docker/compose/docker-compose.env
# Edit docker-compose.env:
#   - PAPERLESS_OCR_LANGUAGE=eng
#   - PAPERLESS_TIME_ZONE=America/Los_Angeles
#   - USERMAP_UID=<id -u>    # if using bind-mounts
#   - USERMAP_GID=<id -g>

cat > .env <<EOF
COMPOSE_PROJECT_NAME=paperless
PAPERLESS_SECRET_KEY=$(openssl rand -hex 32)
PAPERLESS_ADMIN_USER=admin
PAPERLESS_ADMIN_PASSWORD=<strong-password>
PAPERLESS_ADMIN_MAIL=you@example.com
# For external Postgres (not used when compose owns it):
# PAPERLESS_DBHOST=db
# PAPERLESS_DBUSER=paperless
# PAPERLESS_DBPASS=paperless
EOF

docker compose up -d
docker compose logs -f webserver
```

Visit `http://<host>:8000/` and log in with the admin creds you set.

### Canonical Postgres compose (from upstream, main branch)

```yaml
services:
  broker:
    image: docker.io/library/redis:8
    restart: unless-stopped
    volumes:
      - redisdata:/data
  db:
    image: docker.io/library/postgres:18
    restart: unless-stopped
    volumes:
      - pgdata:/var/lib/postgresql
    environment:
      POSTGRES_DB: paperless
      POSTGRES_USER: paperless
      POSTGRES_PASSWORD: paperless
  webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:v2.20.15
    restart: unless-stopped
    depends_on:
      - db
      - broker
    ports:
      - "8000:8000"
    volumes:
      - data:/usr/src/paperless/data
      - media:/usr/src/paperless/media
      - ./export:/usr/src/paperless/export
      - ./consume:/usr/src/paperless/consume
    env_file: docker-compose.env
    environment:
      PAPERLESS_REDIS: redis://broker:6379
      PAPERLESS_DBHOST: db
volumes:
  data:
  media:
  pgdata:
  redisdata:
```

### Reverse proxy (Caddy)

```caddy
paperless.example.com {
    reverse_proxy localhost:8000
}
```

Set `PAPERLESS_URL=https://paperless.example.com` in `docker-compose.env` so Django accepts the host header and generates correct absolute URLs.

## Data layout

| Volume | Content |
|---|---|
| `data:/usr/src/paperless/data` | SQLite DB (if used), search index, classifier models, caches. |
| `media:/usr/src/paperless/media` | **The archived documents**. This is the only irreplaceable data aside from Postgres — the originals live here. |
| `./consume` (host bind) | Drop scans here; Paperless auto-imports. |
| `./export` (host bind) | Destination for `document_exporter` backups. |
| `pgdata:/var/lib/postgresql` | Postgres data. |
| `redisdata:/data` | Redis persistence (safe to lose; just queue state). |

## Backup

Two complementary backup approaches:

### 1. `document_exporter` (upstream-recommended)

Creates a portable archive of every document + metadata as JSON:

```bash
# Ensure ./export exists and is writable, then:
docker compose exec -T webserver document_exporter ../export
# Archive and off-site:
sudo tar -czf paperless-export-$(date +%F).tar.gz export/
```

Can be restored on any Paperless instance (same or newer version) via `document_importer`.

### 2. Volume snapshot (belt + braces)

```bash
docker compose stop
docker compose run --rm -v paperless_data:/data:ro -v paperless_media:/media:ro \
  -v "$PWD":/backup alpine tar -czf /backup/paperless-volumes-$(date +%F).tar.gz /data /media
docker compose exec -T db pg_dump -U paperless paperless > paperless-db-$(date +%F).sql
docker compose start
```

## Upgrade procedure

```bash
# 1. Snapshot (at minimum, run document_exporter)
docker compose exec -T webserver document_exporter ../export

# 2. Read release notes at https://github.com/paperless-ngx/paperless-ngx/releases
#    Major bumps (e.g. 1.x → 2.0) occasionally require migration steps or
#    classifier retrains.

# 3. Pull + up
docker compose pull
docker compose up -d
docker compose logs -f webserver  # watch for migration output
```

Django migrations run on container start. If a migration fails, the container will not become healthy — check logs and file an issue with the exact error.

## OCR & language packs

The default image ships with `eng`. To add more:

```yaml
environment:
  PAPERLESS_OCR_LANGUAGE: "deu+eng"   # multiple languages: + separated
  PAPERLESS_OCR_LANGUAGES: "deu eng"  # space-separated list to INSTALL at boot
```

On first start with a new language, the container runs `apt install tesseract-ocr-<lang>` which can take minutes. After that, it's cached in the container's Tesseract dir.

## Common env vars

| Var | Purpose |
|---|---|
| `PAPERLESS_URL` | Public URL; required when behind a reverse proxy (Django CSRF / `ALLOWED_HOSTS`). |
| `PAPERLESS_SECRET_KEY` | Django secret. Non-empty, random, never shared. |
| `PAPERLESS_TIME_ZONE` | E.g. `America/Los_Angeles`. |
| `PAPERLESS_OCR_LANGUAGE` / `PAPERLESS_OCR_LANGUAGES` | Which languages to use / install. |
| `PAPERLESS_TIKA_ENABLED` + `PAPERLESS_TIKA_ENDPOINT` + `PAPERLESS_TIKA_GOTENBERG_ENDPOINT` | Wire up Tika/Gotenberg if running them. |
| `PAPERLESS_CONSUMER_POLLING` | Set to non-zero for FS that don't support inotify (SMB/NFS). |
| `PAPERLESS_CONSUMER_RECURSIVE` | Scan subfolders of `consume/`. |
| `PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS` | Use subfolder names as tags. |
| `USERMAP_UID` / `USERMAP_GID` | File ownership for bind mounts. |
| `PAPERLESS_ADMIN_USER` / `PAPERLESS_ADMIN_PASSWORD` / `PAPERLESS_ADMIN_MAIL` | Bootstrap admin — only applied if no users exist. |

Full reference: <https://docs.paperless-ngx.com/configuration/>

## Gotchas

- **DO NOT run on an untrusted host.** Documents are stored in the clear in the `media` volume. Local-network or VPN-only exposure is the intended model.
- **Consumer requires inotify.** If `consume/` lives on SMB/NFS/CIFS, set `PAPERLESS_CONSUMER_POLLING=30` (seconds) — otherwise new files will sit forever.
- **UID/GID mismatches on bind-mounts.** The container runs as the user specified by `USERMAP_UID`/`USERMAP_GID`. Without matching host permissions, the consumer can't read dropped files or write to `media/`. Set both to your `id -u` / `id -g`.
- **`PAPERLESS_URL` is Django-strict.** Accessing via an un-listed URL produces a 400 Bad Request with a cryptic "DisallowedHost" log message. Always set `PAPERLESS_URL` when behind a reverse proxy.
- **Admin bootstrap vars only work on an empty DB.** `PAPERLESS_ADMIN_*` env creates the admin only if no users exist. To change an existing password, use `docker compose exec webserver python manage.py changepassword <user>` or the web UI.
- **Running with SQLite at scale hurts.** Full-text search + classifier training against a SQLite `data.db` slows down hard past ~20k documents. PostgreSQL scales much better.
- **Huge files kill ingestion.** Default `PAPERLESS_CONSUMER_MAX_FILE_SIZE` is unbounded but memory constraints + OCR time balloon for multi-hundred-page PDFs. Pre-split very large PDFs before consumption.
- **Tika + Gotenberg are separate containers consuming real RAM.** Expect ~500MB each. Only enable if you ingest Office docs.
- **classifier training runs on a schedule + after bulk imports.** If CPU spikes at odd times, that's probably it. `PAPERLESS_TRAIN_*` tunables control frequency.
- **OCR re-runs are opt-in.** Changing OCR settings after the fact doesn't automatically re-OCR existing documents — use the admin UI's "Redo OCR" action or the `document_retagger` / `document_archiver` management commands.
- **Version-to-version exporter compatibility is forward-only.** Export from v2.x → import into v2.y works. Exporting v2 → importing v1 does not. Always upgrade the target instance to at-or-above the source version before import.
- **Backups of `media/` + Postgres are the source of truth — search index is derivable.** If disk space is tight, skip `data/` in backups; it gets rebuilt on first boot.
- **Two-factor / SSO requires extra config.** Paperless supports OIDC / SAML via env vars as of v2.x; see <https://docs.paperless-ngx.com/configuration/#authentication>. Not enabled by default.

## Links

- Upstream repo: <https://github.com/paperless-ngx/paperless-ngx>
- Docs: <https://docs.paperless-ngx.com/>
- Setup guide: <https://docs.paperless-ngx.com/setup/>
- Configuration reference: <https://docs.paperless-ngx.com/configuration/>
- Compose files: <https://github.com/paperless-ngx/paperless-ngx/tree/main/docker/compose>
- install.sh: <https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/install-paperless-ngx.sh>
- Releases: <https://github.com/paperless-ngx/paperless-ngx/releases>
- Demo: <https://demo.paperless-ngx.com/>
- Matrix room: <https://matrix.to/#/#paperless:matrix.org>
