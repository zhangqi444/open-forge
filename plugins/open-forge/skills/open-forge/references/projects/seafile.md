---
name: Seafile
description: High-performance file sync + share with client-side encryption, Libraries as units of sync, online Markdown ("SeaDoc") + Wiki editing, optional face-recognition AI, and a proprietary efficient transfer protocol. Community Edition AGPL-3.0; Professional Edition commercial. C + Python + Django.
---

# Seafile

Seafile is the "Dropbox for the file-sync-is-a-library crowd" — files live in **Libraries** (optionally client-side encrypted), sync is snappy thanks to a custom binary protocol, SeaDoc gives you Notion-like collaborative documents, and an AI tier (opt-in) adds face recognition + LLM integration. Native clients for Windows/macOS/Linux/Android/iOS.

Two editions:
- **Community Edition (CE)** — AGPL-3.0, open source, most features
- **Professional Edition (PE)** — proprietary, adds clustering, S3 storage, SAML, auditing

This recipe covers CE (the `seafileltd/seafile-mc` image). PE is a separate Docker image with a license key.

- Upstream repo: <https://github.com/haiwen/seafile> (core) + <https://github.com/haiwen/seahub> (web UI)
- Docker repo: <https://github.com/haiwen/seafile-docker>
- Compose + env: <https://github.com/haiwen/seafile-admin-docs/tree/master/manual/repo/docker/ce>
- Docs: <https://manual.seafile.com/latest/setup/overview/>

## Architecture in one minute

Seafile CE 13.x Docker stack has 3 required + several optional containers:

1. **`seafile`** (`seafileltd/seafile-mc:13.0-latest`) — all-in-one: seaf-server (C, sync protocol), seahub (Django web UI), go-fileserver, nginx on :80
2. **`db`** — MariaDB 10.11 (required; three schemas: `ccnet_db`, `seafile_db`, `seahub_db`)
3. **`redis`** — cache + session store (replaces memcached in 13.x onwards)

Optional add-ons layered via `COMPOSE_FILE` chain (compose merge):

- **caddy.yml** — Caddy reverse proxy with auto-TLS (via `lucaslorentz/caddy-docker-proxy` labels)
- **seadoc.yml** — SeaDoc collaborative Markdown editor (port routed via `/sdoc-server`)
- **notification-server.yml** — real-time WebSocket push for client notifications
- **face-embedding/{cpu,cuda,rocm}.yml** — AI face recognition
- **seafile-ai.yml** — LLM-backed chat with your files

## Compatible install methods

| Infra       | Runtime                                                          | Notes                                                                |
| ----------- | ---------------------------------------------------------------- | -------------------------------------------------------------------- |
| Single VM   | Docker Compose (`seafileltd/seafile-mc`)                         | **Recommended CE path.** 2 GB RAM min, 4 GB realistic                 |
| Single VM   | Native binary (Ubuntu/CentOS)                                   | Works; Docker is upstream-preferred                                   |
| Kubernetes  | PE with clustering (paid)                                        | CE doesn't support multi-node; PE required                            |
| Cluster     | `seafile-admin-docs/manual/repo/docker/cluster/` (PE only)      | 3+ nodes for HA; PE license required                                  |
| Commercial  | SeaCloud.cc (hosted by Seafile Ltd.)                             | SaaS                                                                  |

## Inputs to collect

| Input                                   | Example                             | Phase      | Notes                                                             |
| --------------------------------------- | ----------------------------------- | ---------- | ----------------------------------------------------------------- |
| `SEAFILE_SERVER_HOSTNAME`               | `seafile.example.com`               | DNS        | Baked into generated config — **change requires manual config edit + restart** |
| `SEAFILE_SERVER_PROTOCOL`               | `https` (prod) / `http` (LAN only) | Runtime    | Determines all generated public URLs                              |
| `INIT_SEAFILE_MYSQL_ROOT_PASSWORD`      | strong value                        | DB bootstrap | MariaDB root; only used on FIRST boot to create schemas            |
| `SEAFILE_MYSQL_DB_PASSWORD`             | strong value                        | DB         | App-level DB user; created on first boot                          |
| `INIT_SEAFILE_ADMIN_EMAIL`              | `admin@example.com`                 | Bootstrap  | First admin login                                                 |
| `INIT_SEAFILE_ADMIN_PASSWORD`           | strong value (NOT `asecret`)        | Bootstrap  | Default in env template is `asecret` — REPLACE                    |
| `JWT_PRIVATE_KEY`                       | `openssl rand -base64 32`           | Runtime    | **Required.** Signs JWTs between services                          |
| `TIME_ZONE`                             | `Europe/Paris`                      | Runtime    | Affects file-modified-timestamp display                            |
| `SEAFILE_VOLUME`                        | `/opt/seafile-data`                 | Data       | File blobs, logs, generated config live here                      |
| `SEAFILE_MYSQL_VOLUME`                  | `/opt/seafile-mysql/db`             | Data       | MariaDB data dir                                                   |
| `REDIS_PASSWORD`                        | strong value                        | Runtime    | Redis is required in 13.x                                          |

## Install via upstream Docker Compose (CE)

From <https://manual.seafile.com/latest/setup/setup_ce_by_docker/>:

```sh
# 1. Set up workdir
mkdir -p /opt/seafile-compose && cd /opt/seafile-compose

# 2. Download compose + env files
curl -OL https://raw.githubusercontent.com/haiwen/seafile-admin-docs/master/manual/repo/docker/ce/seafile-server.yml
curl -OL https://raw.githubusercontent.com/haiwen/seafile-admin-docs/master/manual/repo/docker/ce/env
curl -OL https://raw.githubusercontent.com/haiwen/seafile-admin-docs/master/manual/repo/docker/caddy.yml
curl -OL https://raw.githubusercontent.com/haiwen/seafile-admin-docs/master/manual/repo/docker/seadoc.yml
mv env .env

# 3. Edit .env — required changes:
#    SEAFILE_SERVER_HOSTNAME=seafile.example.com
#    SEAFILE_SERVER_PROTOCOL=https  (for production)
#    INIT_SEAFILE_MYSQL_ROOT_PASSWORD=<strong>
#    SEAFILE_MYSQL_DB_PASSWORD=<strong>
#    INIT_SEAFILE_ADMIN_EMAIL=admin@example.com
#    INIT_SEAFILE_ADMIN_PASSWORD=<strong, NOT 'asecret'>
#    JWT_PRIVATE_KEY=<openssl rand -base64 32>
#    REDIS_PASSWORD=<strong>
#    TIME_ZONE=Europe/Paris
vim .env

# 4. Bring up (COMPOSE_FILE in .env chains the yml files)
docker compose up -d

# 5. Wait ~90 s for MariaDB init + schema migrations; watch logs
docker compose logs -f seafile
# Look for "Your Seafile server is started" line
```

Browse `https://seafile.example.com` — log in as `INIT_SEAFILE_ADMIN_EMAIL` + `INIT_SEAFILE_ADMIN_PASSWORD`.

### Without Caddy (use your own reverse proxy)

Remove `caddy.yml` from `COMPOSE_FILE` in `.env`, then uncomment the port mapping in `seafile-server.yml`:

```yaml
  seafile:
    ports:
      - "80:80"            # map to whatever host port your proxy forwards to
```

Point Caddy/Traefik/nginx at `http://<host>:80`, set `SEAFILE_SERVER_PROTOCOL=https` in `.env` for correct generated URLs.

## Data & config layout

Inside `$SEAFILE_VOLUME` (default `/opt/seafile-data`, mounted as `/shared` in the container):

- `seafile-data/` — file content blocks (deduplicated, sharded)
- `seafile-data/library-template/` — library template files
- `seafile/` — seaf-server runtime state
- `seahub/` — seahub media, avatars, thumbnails
- `ccnet/` — ccnet runtime state (group + user registry)
- `conf/` — generated config files (`seafile.conf`, `seahub_settings.py`, `ccnet.conf`, `gunicorn.conf.py`) — **safe to edit for advanced tuning**
- `logs/` — all service logs
- `ssl/` — TLS certs if handled internally (usually not)

MariaDB data: `$SEAFILE_MYSQL_VOLUME` (default `/opt/seafile-mysql/db`).

## Backup

From <https://manual.seafile.com/latest/administration/backup_recovery/>:

```sh
# Stop writes (optional but recommended for consistency)
docker compose stop seafile

# 1. Database dump
docker compose exec -T db mariadb-dump -uroot -p<INIT_SEAFILE_MYSQL_ROOT_PASSWORD> \
  --all-databases --single-transaction | gzip > seafile-db-$(date +%F).sql.gz

# 2. File data
tar czf seafile-data-$(date +%F).tgz /opt/seafile-data

# 3. .env (contains all secrets)
cp .env seafile-env-$(date +%F)

docker compose start seafile
```

For very large deployments, use a dedicated backup script that `rsync`s `/opt/seafile-data/seafile-data/` (append-only blob store; can be rsync'd hot).

## Upgrade

1. Releases: <https://github.com/haiwen/seafile/releases>.
2. Update `SEAFILE_IMAGE` in `.env` (e.g. `seafileltd/seafile-mc:13.0-latest` → `14.0-latest` when available).
3. `docker compose pull && docker compose down && docker compose up -d`.
4. Seafile runs migrations on startup — watch logs.
5. **Major upgrades may introduce new required services** (e.g. `redis` was added in 13.x). Check upstream upgrade notes.
6. Upgrade one major at a time.
7. **Client compatibility:** update desktop/mobile clients after server upgrade; older clients usually keep working but new features (like SeaDoc 2.0) need matching versions.

## Gotchas

- **Default `INIT_SEAFILE_ADMIN_PASSWORD=asecret`** in the upstream `.env` template. Public instance + unchanged default = instant admin compromise. Change before first `docker compose up`.
- **`INIT_*` variables only apply on first boot.** Changing `INIT_SEAFILE_ADMIN_PASSWORD` after the schema is created does nothing — rotate passwords via the web UI (or via `seafile-admin` CLI inside the container).
- **`SEAFILE_SERVER_HOSTNAME` change is not hot-swap.** Seahub writes the hostname into `seahub_settings.py` on first boot. Changing it later requires editing `/shared/seafile/conf/seahub_settings.py` manually + restart.
- **Encrypted libraries use CLIENT-side encryption.** The server never sees plaintext. Forgetting the library password = data loss; there's no admin reset.
- **Redis is required in 13.x** (replaced memcached as the default cache). If you're migrating from 12.x, the compose layout changed — don't try to preserve the old memcached service.
- **MariaDB 10.11 is upstream-recommended.** Other versions (MySQL 8, MariaDB 11) usually work but aren't tested. MariaDB upgrade across majors inside the container requires `--auto-upgrade` (already set in upstream compose) + patience on first boot.
- **File blobs are content-addressable + deduplicated.** Renaming a file = free. Copying = free (same hash). But deleting files only frees storage after the garbage collector runs (`seaf-gc`) — not automatic in CE; schedule manually.
- **No CalDAV / CardDAV.** Seafile is file-sync, not Nextcloud-level groupware. For calendars, bolt on a separate app.
- **File locking is a PE feature.** CE has no file locking — last-write wins. Use OnlyOffice/Collabora integration if you need lock-on-edit.
- **Mobile clients need direct port :443.** They don't follow all reverse-proxy niceties; keep a clean Caddy/nginx chain.
- **SeaDoc is a separate service.** `seadoc.yml` in the compose chain. If you disable it, the SeaDoc option in the "New" menu disappears. Existing SeaDoc files become read-only raw Markdown.
- **Object storage (S3/OSS/etc.) is a PE feature.** CE stores blobs on local disk only. Plan for 1× your expected content size in disk (no cloud tiering on CE).
- **Face recognition / AI are opt-in.** `ENABLE_FACE_RECOGNITION=true` requires the extra compose file (`face-embedding/{cpu,cuda,rocm}.yml`). Opens a privacy trade-off — faces are embedded locally, not sent to a third party, but consent from library members matters.
- **SeaDoc URL routing is strict.** `SEADOC_SERVER_URL` must be `${SEAFILE_SERVER_PROTOCOL}://${SEAFILE_SERVER_HOSTNAME}/sdoc-server`. Caddy labels in compose already handle the path routing; custom reverse proxies must proxy `/sdoc-server/` to the SeaDoc container.
- **Max upload size** defaults to 100 MB in nginx; large files fail silently (the client retries but the final chunk hits nginx's limit). Adjust `client_max_body_size` + `SEAFILE_NGINX_CLIENT_MAX_BODY_SIZE` env.
- **`seafile-admin` CLI** is the escape hatch for operations the web UI doesn't support: `docker compose exec seafile seafile-admin` gives you user create/reset-password/etc.
- **AGPL-3.0 CE.** Running a modified CE as a public service requires offering source. PE is proprietary — license by user count.
- **GDPR: encrypted libraries + per-library retention + admin-level audit logs** are supported. For EU compliance, PE's audit log is stricter.

## Links

- Core repo: <https://github.com/haiwen/seafile>
- Seahub (web UI) repo: <https://github.com/haiwen/seahub>
- Docker repo: <https://github.com/haiwen/seafile-docker>
- Admin docs repo: <https://github.com/haiwen/seafile-admin-docs>
- Docs home: <https://manual.seafile.com/latest/>
- Docker install: <https://manual.seafile.com/latest/setup/setup_ce_by_docker/>
- Compose (CE): <https://github.com/haiwen/seafile-admin-docs/tree/master/manual/repo/docker/ce>
- Compose (PE cluster): <https://github.com/haiwen/seafile-admin-docs/tree/master/manual/repo/docker/cluster>
- Upgrade guide: <https://manual.seafile.com/latest/setup/upgrade/>
- Backup + recovery: <https://manual.seafile.com/latest/administration/backup_recovery/>
- Docker Hub: <https://hub.docker.com/r/seafileltd/seafile-mc>
- SeaCloud (SaaS): <https://seacloud.cc>
