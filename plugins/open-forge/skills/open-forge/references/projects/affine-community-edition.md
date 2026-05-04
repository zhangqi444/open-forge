---
name: affine-community-edition
description: AFFiNE Community Edition recipe for open-forge. Privacy-first, self-hosted alternative to Notion + Miro. Covers Docker Compose self-host (the only upstream-blessed method) using the official compose at .docker/selfhost/compose.yaml. Stack: AFFiNE app + migration job + Redis + PostgreSQL (pgvector). Upstream: https://github.com/toeverything/AFFiNE. Docs: https://docs.affine.pro/self-host-affine.
---

# AFFiNE Community Edition

Privacy-first alternative to Notion + Miro — collaborative workspace with docs, whiteboards, and databases. 68k★ on GitHub. Upstream: <https://github.com/toeverything/AFFiNE>. Self-host docs: <https://docs.affine.pro/self-host-affine>.

AFFiNE is a Node.js app listening on port `3010`. The self-host stack (from `.docker/selfhost/compose.yaml`) runs four containers: the AFFiNE app, a one-shot migration job, Redis, and PostgreSQL with pgvector. **The migration job must complete successfully before the app starts** — it runs schema migrations and is a hard dependency.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose (self-host) | <https://github.com/toeverything/AFFiNE/blob/canary/.docker/selfhost/compose.yaml> | Only upstream-blessed self-host method. Linux/Mac with Docker Compose. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which AFFiNE channel do you want?" | `AskUserQuestion`: `stable` / `beta` / `canary` | Sets `AFFINE_REVISION`. Default: `stable`. |
| dns | "What hostname will AFFiNE be accessible at?" | Free-text | Sets `AFFINE_SERVER_HOST`. Required for external access. |
| dns | "Will AFFiNE be served over HTTPS?" | `AskUserQuestion`: `Yes` / `No` | Sets `AFFINE_SERVER_HTTPS=true/false`. |
| db | "PostgreSQL username?" | Free-text | Sets `DB_USERNAME`. |
| db | "PostgreSQL password?" | Free-text (sensitive) | Sets `DB_PASSWORD`. |
| db | "PostgreSQL database name?" | Free-text | Sets `DB_DATABASE`. Default: `affine`. |
| paths | "Where should AFFiNE store uploaded files on the host?" | Free-text path | Sets `UPLOAD_LOCATION`. Mounted at `/root/.affine/storage` in container. |
| paths | "Where should AFFiNE store its config on the host?" | Free-text path | Sets `CONFIG_LOCATION`. Mounted at `/root/.affine/config` in container. |
| paths | "Where should PostgreSQL store data on the host?" | Free-text path | Sets `DB_DATA_LOCATION`. Mounted at `/var/lib/postgresql/data` in container. |

## Services

| Service | Image | Port | Role |
|---|---|---|---|
| `affine` | `ghcr.io/toeverything/affine:${AFFINE_REVISION:-stable}` | `3010` | Main application |
| `affine_migration` | `ghcr.io/toeverything/affine:${AFFINE_REVISION:-stable}` | — | One-shot migration job (runs `node ./scripts/self-host-predeploy.js`) |
| `redis` | `redis` | — | Cache / pub-sub |
| `postgres` | `pgvector/pgvector:pg16` | — | Database (**must** be pgvector image, not plain postgres) |

## Environment variables

| Variable | Default | Required | Description |
|---|---|---|---|
| `AFFINE_REVISION` | `stable` | No | Image tag: `stable`, `beta`, or `canary` |
| `PORT` | `3010` | No | Port AFFiNE listens on |
| `AFFINE_SERVER_HOST` | — | Yes (external access) | Public hostname (e.g. `affine.example.com`) |
| `AFFINE_SERVER_HTTPS` | `false` | No | Set to `true` if serving over HTTPS |
| `DB_USERNAME` | — | Yes | PostgreSQL username |
| `DB_PASSWORD` | — | Yes | PostgreSQL password |
| `DB_DATABASE` | `affine` | No | PostgreSQL database name |
| `DB_DATA_LOCATION` | — | Yes | Host path for PostgreSQL data |
| `UPLOAD_LOCATION` | — | Yes | Host path for uploaded files |
| `CONFIG_LOCATION` | — | Yes | Host path for AFFiNE config |
| `AFFINE_INDEXER_ENABLED` | `false` | No | Full-text search indexer (disabled by default) |

**`DATABASE_URL`** (used internally by AFFiNE):

```
postgresql://${DB_USERNAME}:${DB_PASSWORD}@postgres:5432/${DB_DATABASE:-affine}
```

## Compose

Reference the upstream compose at `.docker/selfhost/compose.yaml`. A minimal working example:

```yaml
services:
  affine:
    image: ghcr.io/toeverything/affine:${AFFINE_REVISION:-stable}
    container_name: affine
    ports:
      - "${PORT:-3010}:3010"
    depends_on:
      affine_migration:
        condition: service_completed_successfully
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
    environment:
      - NODE_OPTIONS=--import=./scripts/register.js
      - AFFINE_CONFIG_PATH=/root/.affine/config
      - REDIS_SERVER_HOST=redis
      - DATABASE_URL=postgresql://${DB_USERNAME}:${DB_PASSWORD}@postgres:5432/${DB_DATABASE:-affine}
      - AFFINE_SERVER_HOST=${AFFINE_SERVER_HOST}
      - AFFINE_SERVER_HTTPS=${AFFINE_SERVER_HTTPS:-false}
    volumes:
      - ${UPLOAD_LOCATION}:/root/.affine/storage
      - ${CONFIG_LOCATION}:/root/.affine/config
    restart: unless-stopped

  affine_migration:
    image: ghcr.io/toeverything/affine:${AFFINE_REVISION:-stable}
    container_name: affine_migration
    command: ["node", "./scripts/self-host-predeploy.js"]
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
    environment:
      - NODE_OPTIONS=--import=./scripts/register.js
      - AFFINE_CONFIG_PATH=/root/.affine/config
      - DATABASE_URL=postgresql://${DB_USERNAME}:${DB_PASSWORD}@postgres:5432/${DB_DATABASE:-affine}
    volumes:
      - ${CONFIG_LOCATION}:/root/.affine/config

  redis:
    image: redis
    container_name: affine_redis
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgres:
    image: pgvector/pgvector:pg16
    container_name: affine_postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_DATABASE:-affine}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - ${DB_DATA_LOCATION}:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USERNAME} -d ${DB_DATABASE:-affine}"]
      interval: 10s
      timeout: 5s
      retries: 5
```

## Deploy

```bash
# 1. Create host directories for volumes
mkdir -p "${UPLOAD_LOCATION}" "${CONFIG_LOCATION}" "${DB_DATA_LOCATION}"

# 2. Create .env with collected values
cat > .env <<EOF
AFFINE_REVISION=stable
PORT=3010
AFFINE_SERVER_HOST=affine.example.com
AFFINE_SERVER_HTTPS=false
DB_USERNAME=affine
DB_PASSWORD=changeme
DB_DATABASE=affine
DB_DATA_LOCATION=/opt/affine/postgres
UPLOAD_LOCATION=/opt/affine/storage
CONFIG_LOCATION=/opt/affine/config
EOF

# 3. Pull images
docker compose pull

# 4. Start stack (migration runs first, then app starts)
docker compose up -d
```

## Verify

```bash
# Check all containers are up
docker compose ps

# Watch migration complete (must exit 0)
docker compose logs affine_migration

# Check app is running
docker compose logs affine

# HTTP health check
curl -sI "http://localhost:3010/"
```

Then open `http://${AFFINE_SERVER_HOST}:3010` in a browser to create your first account.

## Lifecycle

```bash
# Stop
docker compose down

# Start
docker compose up -d

# Upgrade (update AFFINE_REVISION in .env first if pinned)
docker compose pull
docker compose up -d        # migration re-runs automatically on startup

# Logs
docker compose logs -f affine
docker compose logs affine_migration

# Restart app only
docker compose restart affine
```

## Gotchas

- **pgvector/pgvector:pg16 is required.** Do not substitute plain `postgres:16` — AFFiNE requires the pgvector extension and the standard Postgres image won't have it.
- **Migration job must succeed.** `affine_migration` runs `node ./scripts/self-host-predeploy.js` and must exit cleanly before the main app starts. If migration fails, check `docker compose logs affine_migration`. Common causes: wrong DB credentials, missing host directories, or postgres not yet healthy.
- **Set AFFINE_SERVER_HOST for external access.** Without this, AFFiNE defaults to `localhost` and generated share URLs won't resolve from other machines or behind a reverse proxy.
- **AFFINE_INDEXER_ENABLED defaults to false.** Full-text search indexing is off by default. Enable with `AFFINE_INDEXER_ENABLED=true` once your instance is running stably.
- **AFFINE_SERVER_HTTPS must match your actual serving scheme.** Set to `true` when AFFiNE is behind an HTTPS reverse proxy, or links and redirects will use `http://` even when the proxy serves HTTPS.
- **Host directories must exist before first start.** Create `UPLOAD_LOCATION`, `CONFIG_LOCATION`, and `DB_DATA_LOCATION` on the host before running `docker compose up` — Docker bind mounts do not auto-create them with correct permissions.
- **DB credentials are write-once.** Changing `DB_USERNAME` or `DB_PASSWORD` in `.env` after first init breaks connectivity — the config changes but the actual PostgreSQL stored password does not. Treat these as immutable after first deploy.
