---
name: NetBox
description: IP address management (IPAM) + data center infrastructure management (DCIM). Source of truth for racks, devices, cables, circuits, VLANs, prefixes, IPs, tenants, and more. Django/Postgres.
---

# NetBox

NetBox is a Django app for modeling physical and logical network infrastructure. It's widely used as the "source of truth" that drives automation (Ansible, Terraform, Nautobot consumers, custom scripts) through a first-class REST + GraphQL API. Core plus an ecosystem of plugins.

- App repo: <https://github.com/netbox-community/netbox>
- **Docker repo (use for self-hosting):** <https://github.com/netbox-community/netbox-docker>
- Image: `netboxcommunity/netbox` on Docker Hub
- Docs: <https://netboxlabs.com/docs/netbox/> (upstream also at <https://docs.netbox.dev/>)

## Architecture in one minute

Four services in the upstream compose:

1. **netbox** — Django app (Granian WSGI), serves the UI + API on port 8080 inside container
2. **netbox-worker** — RQ worker that consumes background jobs (webhooks, scripts, reports)
3. **postgres** — PostgreSQL 18 (upstream compose pinning)
4. **redis** — Valkey 9.0-alpine (queue + caching; two instances — persistent queue + cache)

## Compatible install methods

| Infra              | Runtime                                    | Notes                                              |
| ------------------ | ------------------------------------------ | -------------------------------------------------- |
| Single VM          | Docker + `netbox-docker` compose           | Recommended                                        |
| Kubernetes         | Official Helm chart (netbox-chart)         | <https://github.com/netbox-community/netbox-chart> |
| Bare metal         | Ubuntu install guide                       | Supported; see upstream docs                       |
| Python venv        | Manual install                             | Documented for development                         |

## Inputs to collect

| Input                      | Example                                        | Phase     | Notes                                                                          |
| -------------------------- | ---------------------------------------------- | --------- | ------------------------------------------------------------------------------ |
| `SECRET_KEY`               | 50+ random chars                               | Runtime   | Django secret key; used for session signing, CSRF, etc.                        |
| `DB_PASSWORD`              | strong random                                  | Runtime   | In `env/netbox.env` AND `env/postgres.env` — must match                        |
| `REDIS_PASSWORD`           | strong random                                  | Runtime   | In `env/netbox.env` AND `env/redis.env` — must match                           |
| `REDIS_CACHE_PASSWORD`     | strong random                                  | Runtime   | Separate from queue; in `netbox.env` + `redis-cache.env`                       |
| `API_TOKEN_PEPPER_1`       | 50+ random chars                               | Runtime   | Salts API tokens at rest — losing it requires regenerating all tokens          |
| `ALLOWED_HOSTS`            | `netbox.example.com`                           | Runtime   | Django `ALLOWED_HOSTS`; comma-sep; blocks Host-header attacks                  |
| Superuser creds            | username / email / password                    | Runtime   | Created via `manage.py createsuperuser` or `SUPERUSER_*` env vars              |
| Expose port                | `8000:8080`                                    | Runtime   | Upstream override file binds 8000 on host → 8080 in container                  |

## Install via Docker Compose

Use the upstream `netbox-docker` repo (default branch: `release`).

```sh
git clone -b release https://github.com/netbox-community/netbox-docker.git
cd netbox-docker
tee docker-compose.override.yml <<'EOF'
services:
  netbox:
    ports:
      - "8000:8080"
EOF

# Edit env/netbox.env, env/postgres.env, env/redis.env, env/redis-cache.env
# — at minimum set unique SECRET_KEY, DB_PASSWORD (in both places), REDIS_PASSWORD (in both),
#   REDIS_CACHE_PASSWORD (in both), API_TOKEN_PEPPER_1, ALLOWED_HOSTS.

docker compose pull
docker compose up -d
```

The entrypoint runs DB migrations automatically on boot. First load of the UI can take 60-90s while the healthcheck finishes.

### Creating a superuser

- **Interactive:** `docker compose exec netbox /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py createsuperuser`
- **Env-var driven (automated):** set `SKIP_SUPERUSER=false`, plus `SUPERUSER_NAME`, `SUPERUSER_EMAIL`, `SUPERUSER_PASSWORD` (and optionally `SUPERUSER_API_TOKEN`) in the netbox env file. Default upstream env has `SKIP_SUPERUSER=true`.

### Pinning a NetBox version

Upstream's `docker-compose.yml` uses `${VERSION-v4.5-4.0.2}` — format is `<netbox-version>-<docker-image-version>`. Set `VERSION=v4.5-4.0.2` in a `.env` file next to the compose file to pin explicitly; see <https://github.com/netbox-community/netbox-docker#version> for tag conventions.

## Data & config layout

- `netbox-postgres` volume → `/var/lib/postgresql` (Postgres data)
- `netbox-redis-data` volume → `/data` (persistent queue)
- `netbox-redis-cache-data` volume → `/data` (ephemeral cache)
- `netbox-media-files` volume → `/opt/netbox/netbox/media` (uploaded images, device type files)
- `netbox-reports-files` volume → `/opt/netbox/netbox/reports` (custom reports)
- `netbox-scripts-files` volume → `/opt/netbox/netbox/scripts` (custom scripts — Python)
- `./configuration/` on host → `/etc/netbox/config:ro` (Python config overrides, plugin config)

## Backup

```sh
# Postgres
docker compose exec -T postgres pg_dump -U netbox netbox | gzip > netbox-$(date +%F).sql.gz

# Media / reports / scripts
for v in netbox-media-files netbox-reports-files netbox-scripts-files; do
  docker run --rm -v "$v":/data -v "$PWD":/backup alpine \
    tar czf "/backup/${v}-$(date +%F).tgz" -C /data .
done
```

Back up `env/*.env` (or your secret manager equivalent) alongside — the `API_TOKEN_PEPPER_1` and `SECRET_KEY` must survive a restore.

## Upgrade

1. Read release notes: <https://github.com/netbox-community/netbox/releases> — NetBox has **data migrations** on most minor versions and occasionally schema-breaking changes on majors.
2. `cd netbox-docker && git pull` to refresh compose + env templates.
3. Bump `VERSION` (in your `.env` next to `docker-compose.yml`) or let it track the docker-compose default.
4. `docker compose pull && docker compose up -d`.
5. The entrypoint runs `manage.py migrate` automatically; watch `docker compose logs -f netbox` for errors. First boot after a major version can take several minutes on large databases.
6. **Always back up Postgres before a major-version upgrade** — NetBox does not auto-roll-back failed migrations.

## Gotchas

- **Use the `release` branch of `netbox-docker`, not `main`.** `main` tracks NetBox's develop branch and is only for contributors.
- **Passwords appear in multiple env files.** `DB_PASSWORD` in `netbox.env` must match `POSTGRES_PASSWORD` in `postgres.env`; `REDIS_PASSWORD` in `netbox.env` must match the value in `redis.env`. Silent mismatches manifest as the app looping in "waiting for database".
- **The default env files ship development-grade placeholder secrets.** Change every password and key **before** first boot — the defaults are in the public repo.
- **`ALLOWED_HOSTS` defaults to `*`** in the upstream env. Restrict it before exposing publicly; Django will 400 any Host header not in the list.
- **`API_TOKEN_PEPPER_1` rotation requires re-issuing every token.** Add `API_TOKEN_PEPPER_2`, rotate tokens, then retire `_1`. Plan this before going to prod if you ever want key rotation.
- **Two Redis instances, not one.** The "redis" service is the RQ queue (AOF persistence, must survive restarts); "redis-cache" is ephemeral. Don't collapse them.
- **Port 8080 is internal.** The upstream compose has no host port binding by default — you add it via `docker-compose.override.yml` (upstream ships an example).
- **Plugins install at build time, not runtime.** To add a plugin you build a custom image (upstream instructions: <https://github.com/netbox-community/netbox-docker#how-to-extend-this-image>) and update your compose to use it. The `configuration/plugins.py` + `PLUGINS` config alone is insufficient.
- **Granian workers** (`GRANIAN_WORKERS=4` by default) use ~200-300 MB RAM each. Lower on small VMs.
- **Major upgrades occasionally require a data-migration dance** (e.g. NetBox 4.x reworked object-permissions). Always read release notes — they are detailed.
- **Postgres 18 is very new.** If you need to run an older managed Postgres, the last widely-supported version is 16; override the `postgres` service image accordingly (and match pg_dump client version for backups).

## Links

- App repo: <https://github.com/netbox-community/netbox>
- Docker repo: <https://github.com/netbox-community/netbox-docker>
- Helm chart: <https://github.com/netbox-community/netbox-chart>
- Docs: <https://netboxlabs.com/docs/netbox/>
- Upgrade guide: <https://github.com/netbox-community/netbox-docker#upgrading-netbox>
- Env var reference: <https://github.com/netbox-community/netbox-docker/blob/release/env/netbox.env>
- Releases: <https://github.com/netbox-community/netbox/releases>
