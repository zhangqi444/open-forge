---
name: Activepieces
description: Open-source, self-hostable workflow automation tool (Zapier-style). Visual flow builder, 200+ pieces (Slack, Gmail, Notion, HTTP, DBs, LLMs), MIT core + commercial enterprise pieces.
---

# Activepieces

Activepieces is a Node.js/TypeScript workflow engine plus a React builder UI. Flows are sequences of "pieces" (integrations); the engine runs on a `app` service that exposes the UI + API and a separate `worker` service that actually executes flow steps. Triggers are either webhook-based, schedule-based, or polling (per-piece).

- Upstream repo: <https://github.com/activepieces/activepieces>
- Image: `ghcr.io/activepieces/activepieces`
- Docs: <https://www.activepieces.com/docs>
- License: **MIT** for core; enterprise pieces under a commercial license (`packages/ee/`)

## Architecture in one minute

- **app** (HTTP on 80 inside container) — UI, REST API, webhooks, schedule manager
- **worker** (multi-replica) — pulls jobs from Redis, runs sandboxed flow steps
- **postgres** (`pgvector/pgvector:0.8.0-pg14`) — users, projects, flows, runs, AI memory
- **redis** (`redis:7.0.7`) — job queue, rate limiter, pub/sub

Workers scale horizontally; the `deploy.replicas: 5` in the sample compose is a starting point — tune up for heavy polling, down for light use.

## Compatible install methods

| Infra              | Runtime                                | Notes                                                                  |
| ------------------ | -------------------------------------- | ---------------------------------------------------------------------- |
| Single VM          | Docker + Compose                       | Recommended; upstream ships `docker-compose.yml` + `tools/deploy.sh`   |
| Kubernetes         | Helm chart (upstream)                  | See <https://github.com/activepieces/activepieces/tree/main/deploy>    |
| Managed (PaaS)     | Render, Railway, etc.                  | Community, unofficial                                                  |

## Inputs to collect

| Input                     | Example                              | Phase   | Notes                                                                                     |
| ------------------------- | ------------------------------------ | ------- | ----------------------------------------------------------------------------------------- |
| `AP_ENCRYPTION_KEY`       | 32-hex string (16 bytes)             | Runtime | **Required.** Encrypts stored credentials (OAuth tokens, API keys) at rest                |
| `AP_JWT_SECRET`           | 64+ random chars                     | Runtime | **Required.** JWT signing                                                                 |
| `AP_FRONTEND_URL`         | `https://flows.example.com`          | Runtime | Full origin; webhooks, OAuth callbacks, emails use it                                     |
| `AP_POSTGRES_*`           | db/user/pw/host/port                 | Runtime | Matches the Postgres container                                                            |
| `AP_REDIS_HOST/PORT`      | `redis` / `6379`                     | Runtime | Default compose values fine                                                                |
| `AP_ENVIRONMENT`          | `prod`                               | Runtime | Enables production logging / rate limits                                                  |
| `AP_EXECUTION_MODE`       | `UNSANDBOXED` or `SANDBOXED`         | Runtime | `SANDBOXED` requires Docker-in-Docker; `UNSANDBOXED` is compose default                   |
| SMTP config (optional)    | host/port/user/pass                  | Runtime | For invites, password reset                                                                |
| Worker replicas           | `5`                                  | Runtime | Scale per load                                                                            |

Full env reference: <https://www.activepieces.com/docs/install/configurations/environment-variables>

## Install via Docker Compose

Upstream provides a deploy script that generates secrets + `.env` for you:

```sh
git clone https://github.com/activepieces/activepieces.git
cd activepieces
./tools/deploy.sh    # interactive; writes .env with secure random AP_ENCRYPTION_KEY, AP_JWT_SECRET
docker compose up -d
```

Or manually:

```sh
cat > .env <<EOF
AP_ENCRYPTION_KEY=$(openssl rand -hex 16)
AP_JWT_SECRET=$(openssl rand -base64 48)
AP_ENVIRONMENT=prod
AP_FRONTEND_URL=https://flows.example.com
AP_ENGINE_EXECUTABLE_PATH=dist/packages/engine/main.js
AP_EXECUTION_MODE=UNSANDBOXED
AP_WEBHOOK_TIMEOUT_SECONDS=30
AP_TRIGGER_DEFAULT_POLL_INTERVAL=5
AP_FLOW_TIMEOUT_SECONDS=600
AP_TELEMETRY_ENABLED=false
AP_POSTGRES_DATABASE=activepieces
AP_POSTGRES_HOST=postgres
AP_POSTGRES_PORT=5432
AP_POSTGRES_USERNAME=activepieces
AP_POSTGRES_PASSWORD=$(openssl rand -hex 24)
AP_REDIS_HOST=redis
AP_REDIS_PORT=6379
EOF
docker compose up -d
```

The upstream compose (<https://github.com/activepieces/activepieces/blob/main/docker-compose.yml>) ships with a *slightly older worker tag than app* at time of writing (`app:0.80.1`, `worker:0.79.0`) — harmonize both to the same release before deploy. Pin to a concrete tag; avoid `latest`.

Browse `https://flows.example.com` → create the admin account (first user becomes platform admin) → build a flow.

## Data & config layout

- Named volume `postgres_data` → `/var/lib/postgresql/data`
- Named volume `redis_data` → `/data` (RDB snapshots)
- Bind mount `./cache` → `/usr/src/app/cache` — piece binary cache; regenerated on demand
- No other mutable state outside these.

## Backup

```sh
docker compose exec -T postgres pg_dump -U "$AP_POSTGRES_USERNAME" "$AP_POSTGRES_DATABASE" | gzip > ap-$(date +%F).sql.gz
```

Critically, **back up `AP_ENCRYPTION_KEY`** alongside the DB dump. Every stored credential in the DB is encrypted with it — a DB without the key is useless.

## Upgrade

1. Check release notes: <https://github.com/activepieces/activepieces/releases>. Version cadence is fast (weekly).
2. Pull latest compose and bump both `app` and `worker` image tags to the **same** version.
3. `docker compose pull && docker compose up -d`.
4. Migrations run automatically on `app` boot. Tail `docker compose logs -f app` and watch for migration errors.
5. For major version bumps (e.g. 0.x floor), take a DB backup first.

## Gotchas

- **Worker version skew** with `app` is risky. The sample compose ships mismatched tags; always deploy them at the same version.
- **`AP_ENCRYPTION_KEY` is permanent** for the lifetime of the DB. Change it and every stored credential (OAuth tokens, API keys, DB passwords) becomes unreadable; users must re-authorize every connection.
- **`AP_EXECUTION_MODE=UNSANDBOXED`** means user-authored code pieces run with worker-container privileges. Acceptable for single-tenant self-host; for multi-tenant, switch to `SANDBOXED` and set up the Docker-in-Docker prerequisites (see docs).
- **Webhooks need `AP_FRONTEND_URL`** correct and reachable publicly (or via tunnel). A wrong value here yields 404s on external webhook triggers.
- **Poll-based triggers** run at `AP_TRIGGER_DEFAULT_POLL_INTERVAL` minutes — 5 by default. Many replicas all polling the same upstream API can rate-limit you; tune down worker count if you see 429s.
- **Postgres uses pgvector image** — if you swap to stock `postgres:14` you'll lose vector search for the AI-memory pieces. Keep `pgvector/pgvector:<ver>` unless you don't use AI pieces.
- **Redis 7.0.7 pinned exactly** in upstream compose. Upgrading Redis requires a dump/reload for persistence safety; do not yolo it.
- **SMTP not required to boot**, but without it password reset + team invites are broken.
- **Enterprise pieces** live under `packages/ee/` and are licensed separately (not MIT). Building the image from source without filtering them out will bundle them; read the license if you distribute builds.
- **Port 80 in container → 8080 on host** per the sample compose. If your reverse proxy targets 80 directly, adjust the `ports:` mapping accordingly.
- **Telemetry on by default** (`AP_TELEMETRY_ENABLED=true` per env example). Set to `false` if you want to opt out.

## Links

- Repo: <https://github.com/activepieces/activepieces>
- Self-host docs: <https://www.activepieces.com/docs/install/overview>
- Env var reference: <https://www.activepieces.com/docs/install/configurations/environment-variables>
- Compose file: <https://github.com/activepieces/activepieces/blob/main/docker-compose.yml>
- Deploy script: <https://github.com/activepieces/activepieces/blob/main/tools/deploy.sh>
- Releases: <https://github.com/activepieces/activepieces/releases>
- Helm chart: <https://github.com/activepieces/activepieces/tree/main/deploy>
