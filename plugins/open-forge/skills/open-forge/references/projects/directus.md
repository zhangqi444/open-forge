---
name: directus-project
description: Directus recipe for open-forge. Headless CMS + instant REST/GraphQL API for any SQL database (Postgres, MySQL, SQLite, MariaDB, MS SQL, CockroachDB, OracleDB). Written in Node.js + Vue 3. Historically BSL/public-source with free self-host for small-scale; **as of 2024-2025 Directus is in a license revision review — check current LICENSE before commercial deployment.** Covers Docker Compose with external Postgres (upstream-recommended for prod), Docker run (quick eval), and the minimum required secrets (KEY, SECRET, ADMIN_EMAIL, ADMIN_PASSWORD).
---

# Directus

Headless CMS + instant REST and GraphQL API on top of any SQL database. Upstream: <https://github.com/directus/directus>. Docs: <https://docs.directus.io>. Cloud: <https://directus.cloud>.

- **Bring your DB** — Postgres, MySQL 8+, SQLite, MariaDB, MS SQL, CockroachDB, OracleDB
- **Reads existing schemas** — point at an existing DB and Directus introspects the schema; no migrations required
- **Auto-generated REST + GraphQL** — every table becomes a collection with full CRUD
- **Vue 3 admin app** — visual data manager for non-technical users
- **Extensible** — custom hooks, endpoints, operations, migrations, flow automations

## ⚠️ License note

Directus has shifted license models multiple times. As of this writing, upstream has publicly posted a **"Directus License Revision: Community Feedback Requested"** thread (<https://community.directus.io/t/directus-license-revision-community-feedback-requested/2125>). Before deploying Directus commercially, **read the current `LICENSE` file in the repo** and the latest blog post on licensing. Historically (BSL) it was free for small/medium self-host, paid for large-scale; future terms may differ. Don't assume "it was free last year = it's free this year."

For individuals / small teams self-hosting for non-commercial or small-commercial use, the practical situation remains the same: self-host works, no license-key check on startup.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose with external DB | <https://docs.directus.io/self-hosted/docker-guide> | ✅ Recommended | Production. BYO Postgres/MySQL. |
| Docker run (SQLite default) | <https://docs.directus.io/self-hosted/quickstart> | ✅ | Evaluation only; SQLite not recommended for prod. |
| `npx directus init` (local npm) | <https://docs.directus.io/self-hosted/quickstart> | ✅ | Dev. |
| Directus Cloud | <https://directus.cloud> | ✅ | Managed hosting from $15/mo. |
| Railway one-click | README § One-Click Deployment | ✅ | Integrated Postgres + Redis + S3 + Directus. |
| Build from source | Turborepo monorepo | ✅ | Core contributors. |

**NOT recommended:**
- The `docker-compose.yml` at the repo root: that's a debug-only multi-DB test harness for contributors (MySQL, MSSQL, Oracle, etc. all fired up simultaneously). Don't use it for production.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `compose` / `docker-run` / `npx` / `cloud` | Drives section. |
| db | "Database?" | `AskUserQuestion`: `postgres` / `mysql` / `mariadb` / `sqlite` / `mssql` / `cockroach` / `oracle` | Use Postgres for most new deploys. |
| db | "Host/port/user/pass/db-name?" | Free-text | Maps to `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_DATABASE`. |
| secrets | "`KEY` (UUID)?" | Free-text, generate `uuidgen` | REQUIRED. Internal signing key for sessions/caching. |
| secrets | "`SECRET` (random)?" | Free-text, generate `openssl rand -hex 32` | REQUIRED. JWT signing secret. Rotating invalidates all tokens. |
| admin | "Admin email?" | Free-text | `ADMIN_EMAIL` — creates the first admin on first boot. |
| admin | "Admin password?" | Free-text (sensitive) | `ADMIN_PASSWORD`. |
| storage | "File storage? (local / s3 / gcs / azure)" | `AskUserQuestion` | `STORAGE_LOCATIONS=local`. S3 recommended for multi-node. |
| cache | "Redis for cache/rate-limit/pubsub?" | Boolean | Optional but highly recommended for production / multi-replica. |
| dns | "Public URL?" | Free-text | `PUBLIC_URL=https://directus.example.com` — used in emails + webhooks. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik)" | `AskUserQuestion` | Directus does not terminate TLS. |

## Install — Docker Compose (production-ish)

Upstream-recommended production compose (adapted from <https://docs.directus.io/self-hosted/docker-guide>):

```yaml
# compose.yaml
services:
  database:
    image: postgis/postgis:16-3.4-alpine    # or postgres:16-alpine if you don't need PostGIS
    volumes:
      - ./data/database:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: 'directus'
      POSTGRES_PASSWORD: 'directus'
      POSTGRES_DB: 'directus'
    healthcheck:
      test: ['CMD', 'pg_isready', '--username=directus', '--dbname=directus']
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  cache:
    image: redis:7-alpine
    healthcheck:
      test: ['CMD-SHELL', "[ $$(redis-cli ping) = 'PONG' ]"]
      interval: 10s

  directus:
    image: directus/directus:11        # pin a major.minor
    ports:
      - 8055:8055
    volumes:
      - ./data/uploads:/directus/uploads
      - ./data/extensions:/directus/extensions
    depends_on:
      database:
        condition: service_healthy
      cache:
        condition: service_started
    environment:
      SECRET: '<openssl rand -hex 32>'
      KEY: '<uuidgen>'

      ADMIN_EMAIL: 'admin@example.com'
      ADMIN_PASSWORD: '<strong-password>'

      DB_CLIENT: 'pg'
      DB_HOST: 'database'
      DB_PORT: '5432'
      DB_DATABASE: 'directus'
      DB_USER: 'directus'
      DB_PASSWORD: 'directus'

      CACHE_ENABLED: 'true'
      CACHE_STORE: 'redis'
      REDIS: 'redis://cache:6379'

      PUBLIC_URL: 'https://directus.example.com'
      # STORAGE_LOCATIONS: 's3'
      # STORAGE_S3_DRIVER: 's3'
      # STORAGE_S3_KEY: ...
      # STORAGE_S3_SECRET: ...
      # STORAGE_S3_BUCKET: ...
      # STORAGE_S3_REGION: ...
```

Bring up:

```bash
mkdir -p data/{database,uploads,extensions}
# Generate secrets FIRST and inject via .env or edit compose
docker compose up -d
docker compose logs -f directus
```

Login at `http://<host>:8055/admin/` with the email+password above.

## Install — Docker run (quick eval only)

```bash
# Zero-config SQLite — data lives in the container, NOT for prod
docker run -d \
  --name directus \
  -p 8055:8055 \
  -e KEY=$(uuidgen) \
  -e SECRET=$(openssl rand -hex 32) \
  -e ADMIN_EMAIL=admin@example.com \
  -e ADMIN_PASSWORD=changeme \
  -v "$(pwd)/directus-data:/directus/database" \
  -v "$(pwd)/directus-uploads:/directus/uploads" \
  directus/directus:latest
```

## Install — `npx directus init`

```bash
# Requires Node 22+ and pnpm
mkdir my-directus && cd my-directus
npx directus init
# Prompts for DB type, connection, admin credentials — generates .env + starts.
npx directus start
```

## Reverse proxy (Caddy)

```caddy
directus.example.com {
    reverse_proxy directus:8055
}
```

## Key environment variables

Full reference: <https://docs.directus.io/self-hosted/config-options>. Essentials:

| Var | Required? | Purpose |
|---|---|---|
| `KEY` | ✅ | UUID identifying this project. Used for hashing. |
| `SECRET` | ✅ | Random string. JWT signing. Rotate = invalidate all tokens. |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | Required on first boot | Creates initial admin user. After first boot, these env vars are no-ops (user exists in DB). |
| `DB_CLIENT` | ✅ | `pg`, `mysql`, `sqlite3`, `mssql`, `oracledb`, `cockroachdb` |
| `DB_HOST` / `DB_PORT` / `DB_DATABASE` / `DB_USER` / `DB_PASSWORD` | per-client | Connection. |
| `PUBLIC_URL` | Recommended | Used in email links, OAuth redirect URIs. |
| `STORAGE_LOCATIONS` | ❌ | Comma-separated names; default `local`. |
| `CACHE_ENABLED` | ❌ | `true` for production. Needs `REDIS` or in-memory cache (don't use in-memory for multi-replica). |
| `REDIS` | ❌ | Redis URL for cache, rate limiter, pub/sub. |
| `EMAIL_*` | ❌ | SMTP config for password-reset + user-invite emails. |
| `CORS_ENABLED` / `CORS_ORIGIN` | ❌ | Set if you front Directus API from a browser app on a different origin. |

## Data layout

| Path | Content |
|---|---|
| External PG / MySQL / etc. | All schema + content. Directus creates ~40 `directus_*` tables for its own metadata. |
| `/directus/uploads/` | Uploaded files (if `STORAGE_LOCATIONS=local`). Back up separately from DB. |
| `/directus/extensions/` | Custom extensions (endpoints, hooks, operations, interfaces, displays, layouts, modules). |
| `/directus/database/` | Only populated if `DB_CLIENT=sqlite3`. |

## Backup

```bash
# 1. DB (Postgres example)
docker exec $(docker compose ps -q database) \
  pg_dump -U directus directus | gzip > directus-db-$(date +%F).sql.gz

# 2. Uploads
tar -czf directus-uploads-$(date +%F).tar.gz data/uploads

# 3. Extensions (if you have custom ones)
tar -czf directus-extensions-$(date +%F).tar.gz data/extensions
```

## Upgrade procedure

Major version upgrades (v10 → v11) can include breaking schema changes + extension API changes:

```bash
# 1. Back up DB + uploads FIRST
# 2. Read release notes: https://github.com/directus/directus/releases
# 3. Bump the image tag in compose + pull
docker compose pull
docker compose up -d
docker compose logs -f directus   # watch for migration errors
```

Directus runs its own Knex migrations on startup — DB tables are updated automatically. Extensions (custom code in `/directus/extensions/`) may need updates if they call deprecated APIs.

## Gotchas

- **License is in flux.** Past BSL → ??? — upstream is actively revising. Read the current `LICENSE` file. Don't assume commercial terms from a blog post or Stack Overflow answer.
- **`latest` tag drift.** Pin an explicit version (`directus/directus:11.x.x`) in production. Auto-pull can ship breaking changes.
- **Root-of-repo `docker-compose.yml` is a dev-only multi-DB harness.** Do NOT use it for production — it spins up Postgres + MySQL + MariaDB + MSSQL + Oracle + MinIO + MailDev + CockroachDB + Keycloak simultaneously. Read the docs for the proper production compose.
- **`ADMIN_EMAIL` / `ADMIN_PASSWORD` only work on FIRST boot.** After that, the admin user exists in the DB. Changing the env vars does nothing. To reset admin password, use `docker exec ... npx directus users passwd --email admin@example.com --password newpass`.
- **Rotating `SECRET` logs everyone out.** All JWTs become invalid immediately.
- **`DB_CLIENT=sqlite3` is eval-only.** Single-writer SQLite is fine for demos; production Directus assumes Postgres or MySQL.
- **Extensions loaded from `/directus/extensions/` run in the main Node process.** A misbehaving extension (e.g. a hook with an infinite loop) takes down the API. Test extensions in staging first.
- **Files uploaded via the "Files" module** go to `STORAGE_LOCATIONS` (default `local`). Moving to S3 later requires either a migration script (iterate `directus_files` and re-upload) or accepting split storage.
- **GraphQL schema rebuilds on collection change.** First request after a schema change takes longer. If you have a CI/CD that hits GraphQL immediately after a deploy, add a warmup request or retry logic.
- **Rate limiter needs Redis for multi-replica.** With in-memory cache, each replica rate-limits independently, which means "10 req/min" becomes "10 × replica-count req/min". Use Redis in any HA setup.
- **PUBLIC_URL must match the browser-visible URL exactly** — `https://directus.example.com` without trailing slash. Mismatches break password-reset emails and OAuth redirects.
- **Postgres `postgis/postgis` image** is used only if you want PostGIS geospatial types. Plain `postgres:16-alpine` is fine otherwise.
- **Directus Cloud and self-host do NOT share the same app binaries exactly.** Some Cloud features (backups, SSO Premium providers) are hosted-only. Self-host has the full REST/GraphQL/admin app, which is what 95% of users need.

## Links

- Upstream repo: <https://github.com/directus/directus>
- Docs: <https://docs.directus.io>
- Self-hosting guide: <https://docs.directus.io/self-hosted/docker-guide>
- Config options: <https://docs.directus.io/self-hosted/config-options>
- CLI reference: <https://docs.directus.io/self-hosted/cli>
- Docker Hub: <https://hub.docker.com/r/directus/directus>
- Licensing thread: <https://community.directus.io/t/directus-license-revision-community-feedback-requested/2125>
- Community forum: <https://community.directus.io>
- Releases: <https://github.com/directus/directus/releases>
