---
name: Teable
description: No-code database and Airtable alternative built on PostgreSQL. Spreadsheet-like UI for structured data with real multi-GB scale, API access, and formula/automation support.
---

# Teable

Teable is an open-source Airtable/Notion-database alternative. Unlike tools that store rows in their own engine, Teable reads and writes **real PostgreSQL tables** — you can query the same data from BI tools, psql, or other apps without an export step.

- Upstream repo: <https://github.com/teableio/teable>
- Docs: <https://help.teable.io/>
- Image: `ghcr.io/teableio/teable` + `ghcr.io/teableio/teable-db-migrate`
- Self-hosting entrypoint (official): <https://github.com/teableio/teable/tree/main/dockers/examples/standalone>

## Compatible install methods

| Infra           | Runtime                              | Notes                                                                |
| --------------- | ------------------------------------ | -------------------------------------------------------------------- |
| Single VM       | Docker + Compose (standalone)        | Recommended — upstream's `dockers/examples/standalone` bundle        |
| Multi-node / HA | Docker Swarm                         | Upstream ships `dockers/examples/docker-swarm/`                       |
| Kubernetes      | Helm chart (community)               | Not upstream-official                                                 |
| Cluster (Redis) | Compose cluster example              | `dockers/examples/cluster/` for larger deployments with caching       |

## Inputs to collect

| Input               | Example                                        | Phase   | Notes                                                                    |
| ------------------- | ---------------------------------------------- | ------- | ------------------------------------------------------------------------ |
| `PUBLIC_ORIGIN`     | `https://teable.example.com`                   | Runtime | Full origin incl. scheme; used for OAuth redirects and share links       |
| `POSTGRES_PASSWORD` | strong random                                  | Data    | Set before first boot; changing later requires DB-user alter             |
| `POSTGRES_DB`       | `teable`                                       | Data    | Defaults to `example` in upstream `.env` — change for prod               |
| `POSTGRES_USER`     | `teable`                                       | Data    | Defaults to `example`                                                    |
| `TIMEZONE`          | `UTC`                                          | Runtime | Used by both app and Postgres containers                                 |
| SMTP (optional)     | `BACKEND_MAIL_HOST`, port, user, pass, sender  | Runtime | Required for invites, password reset                                     |

## Install via Docker Compose

Upstream's standalone example (verbatim at <https://github.com/teableio/teable/blob/main/dockers/examples/standalone/docker-compose.yaml>) runs three containers: the app, Postgres 15.4, and a one-shot Prisma migration runner.

```sh
mkdir -p teable && cd teable
curl -fsSL https://raw.githubusercontent.com/teableio/teable/main/dockers/examples/standalone/docker-compose.yaml -o docker-compose.yaml
curl -fsSL https://raw.githubusercontent.com/teableio/teable/main/dockers/examples/standalone/.env -o .env

# Pin image tags in the compose file — replace :latest with a release from
# https://github.com/teableio/teable/releases (use the matching tag on
# ghcr.io/teableio/teable and ghcr.io/teableio/teable-db-migrate).

# Edit .env:
#   POSTGRES_PASSWORD=<strong random>
#   POSTGRES_DB=teable
#   POSTGRES_USER=teable
#   PUBLIC_ORIGIN=https://teable.example.com
#   TIMEZONE=UTC

docker compose up -d
```

`teable-db-migrate` runs Prisma migrations and exits `0`; the app container waits on `service_completed_successfully`. Browse `PUBLIC_ORIGIN`; first signup gets admin.

### Email (required for invites)

Uncomment and set these in `.env`:

```
BACKEND_MAIL_HOST=smtp.example.com
BACKEND_MAIL_PORT=465
BACKEND_MAIL_SECURE=true
BACKEND_MAIL_SENDER=noreply@example.com
BACKEND_MAIL_SENDER_NAME=Teable
BACKEND_MAIL_AUTH_USER=...
BACKEND_MAIL_AUTH_PASS=...
```

## Data & config layout

- Volume `teable-data` → `/app/.assets` — uploaded files, local attachment storage
- Volume `teable-db` → `/var/lib/postgresql/data` — Postgres data directory
- The compose exposes Postgres on host port `42345` (only localhost-bind in production) and the app on port `3000`
- All app config is env-var driven — see full reference at <https://help.teable.io/deploy/environment-variables>

## Backup

```sh
# Postgres dump (all app state)
docker compose exec -T teable-db pg_dump -U teable teable | gzip > teable-db-$(date +%F).sql.gz

# Attachments
docker run --rm -v teable_teable-data:/data -v "$PWD":/backup alpine \
  tar czf /backup/teable-assets-$(date +%F).tgz -C /data .
```

For bind-mount installations (recommended for operability), swap the volume mounts to `./docker/teable/data` and `./docker/db/data` as hinted in the upstream compose comments, then back up with regular `tar` + `pg_dump`.

## Upgrade

1. Check <https://github.com/teableio/teable/releases> for breaking changes.
2. Bump the image tag of **both** `ghcr.io/teableio/teable` and `ghcr.io/teableio/teable-db-migrate` in `docker-compose.yaml`.
3. `docker compose pull && docker compose up -d`.
4. The migrate container runs Prisma migrations automatically. Inspect its logs: `docker compose logs teable-db-migrate`.
5. Take a Postgres dump before major-version upgrades.

## Gotchas

- **Default env values are demo-only.** Upstream ships `POSTGRES_USER=example`, `POSTGRES_PASSWORD=example2password`, `POSTGRES_DB=example`. Change these before you expose the instance — don't leave the shipped credentials in production.
- **Exposed host Postgres port (42345) is a default.** Remove the `ports:` mapping on `teable-db`, or bind it to `127.0.0.1:42345` only, unless you specifically need external BI access.
- **App image and migrate image must be kept in lockstep.** Upgrading only one half can leave migrations broken. Always bump both tags together.
- **Telemetry — Teable pings an aggregator by default.** Disable by setting `NEXT_PUBLIC_ENABLE_TELEMETRY=false` in `.env`.
- **`NEXT_ENV_IMAGES_ALL_REMOTE=true`** (set in compose) disables Next.js image-domain allowlisting. If you front Teable with a stricter reverse proxy CSP, test uploads/embeds.
- **Postgres 15.4 is pinned** in the upstream compose. Bumping to 16/17 requires a manual `pg_dumpall` + re-init — Postgres doesn't auto-upgrade data dirs across majors.
- **S3-compatible object storage** is configurable via `BACKEND_STORAGE_*` env vars; default stores attachments on local disk in the `teable-data` volume which can grow unbounded.
- **No built-in SSO** in the open source distribution — SAML/OIDC sit behind a feature gate; check the current edition at <https://help.teable.io/>.

## Links

- Repo: <https://github.com/teableio/teable>
- Standalone compose: <https://github.com/teableio/teable/tree/main/dockers/examples/standalone>
- Cluster/Swarm examples: <https://github.com/teableio/teable/tree/main/dockers/examples>
- Env var reference: <https://help.teable.io/deploy/environment-variables>
- Docs: <https://help.teable.io/>
- Releases: <https://github.com/teableio/teable/releases>
