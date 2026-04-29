---
name: budibase-project
description: Budibase recipe for open-forge. GPL-3.0 open-source low-code platform for building internal tools, agents, apps, and automations — connect to databases (Postgres/MySQL/MS SQL/MongoDB/Oracle/CouchDB/REST/GraphQL/Airtable/Google Sheets/S3/Snowflake/DynamoDB/MariaDB/ArangoDB), design UIs with a drag-and-drop builder, ship workflows with automation steps, AI agents (via LiteLLM). Architecture: app-service + worker + proxy + MinIO (object storage) + CouchDB (app metadata) + Redis + LiteLLM — 7 containers. Alternatives to Retool / Appsmith / Outerbase. Covers the official docker-compose stack, env var reference (SECRETS: JWT_SECRET, API_ENCRYPTION_KEY, INTERNAL_API_KEY, COUCH_DB_*, MINIO_*, REDIS_PASSWORD, LITELLM_MASTER_KEY), DigitalOcean/K8s alternatives, and the hosting.properties env-file pattern.
---

# Budibase

GPL-3.0 open-source operations / low-code platform. Upstream: <https://github.com/Budibase/budibase>. Docs: <https://docs.budibase.com>. Website: <https://www.budibase.com>. Hosted: <https://budibase.app>.

From upstream (2026 positioning):

> AI Agents that run your operations

Budibase has evolved from "internal-tool builder" (2020 era, Retool/Appsmith competitor) to an "operations platform" — same drag-and-drop builder + database connectors, now with AI agents integrated.

## What you build with it

- **Internal tools** — admin panels, CRUD interfaces, dashboards on top of existing databases.
- **Approval workflows** — routing requests through chains of approvers, with branches.
- **AI agents** — agents that understand natural-language requests and execute the underlying workflow (via LiteLLM — supports OpenAI / Anthropic / Google / local Ollama / any model LiteLLM proxies).
- **Apps** — form-based data entry, user portals, customer self-service.
- **Automations** — triggered workflows (on-schedule, on-webhook, on-data-change) that call integrations + update databases + send emails / Slack / etc.
- **Portals** — end-user-facing UIs built on the same builder.

## Database connectors

Built-in:

PostgreSQL, MySQL, MS SQL Server, MongoDB, Oracle, CouchDB, REST / OpenAPI, GraphQL, Airtable, Google Sheets, Amazon S3, Snowflake, DynamoDB, MariaDB, ArangoDB, ElasticSearch, Firebase, Redis, plus Budibase's own built-in database.

## Architecture — the 7 containers

From upstream `hosting/docker-compose.yaml`:

| Service | Image | Role |
|---|---|---|
| `app-service` | `budibase/apps` | App runtime — serves user apps |
| `worker-service` | `budibase/worker` | Builder service — authentication, tenants, app mgmt |
| `proxy-service` | `budibase/proxy` | nginx — routes traffic to app/worker/minio/couchdb |
| `minio-service` | `minio/minio` | Object storage — file uploads, plugins |
| `couchdb-service` | `apache/couchdb` | App metadata DB |
| `redis-service` | `redis:alpine` | Cache + job queue |
| `litellm-service` | `ghcr.io/berriai/litellm` | LLM proxy (new in 2026) — unified API for OpenAI / Anthropic / Google / Ollama / 100+ providers |

All orchestrated via `proxy-service` (the single entry point on `${MAIN_PORT}`).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (official) | <https://github.com/Budibase/budibase/tree/master/hosting> | ✅ Recommended | Standard self-host. |
| Kubernetes (Helm) | <https://github.com/Budibase/budibase/tree/master/charts/budibase> | ✅ | Clusters. |
| DigitalOcean 1-click | <https://marketplace.digitalocean.com/apps/budibase> | ✅ | DO users. |
| Budibase Cloud (hosted) | <https://budibase.app> | ✅ (free tier + paid) | Don't self-host. |
| `npx @budibase/cli init` (single-container dev) | <https://docs.budibase.com/docs/hosting-methods> | ✅ | Dev / tiny eval. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `kubernetes-helm` / `digitalocean-1click` | Drives section. |
| dns | "Public URL?" | e.g. `https://budibase.example.com` | Becomes `PLATFORM_URL` env var. |
| ports | "Proxy port?" | Default `80` (= `MAIN_PORT`) | Single public port for all traffic (proxy routes internally). |
| secrets | "Four random secrets?" | 4 × 64-char random strings | `JWT_SECRET`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `INTERNAL_API_KEY`, `API_ENCRYPTION_KEY`. Generate: `openssl rand -hex 64`. |
| auth | "Admin email + password?" | Free-text (sensitive) | `BB_ADMIN_USER_EMAIL` + `BB_ADMIN_USER_PASSWORD` — created on first boot. |
| db | "CouchDB admin user + password?" | Free-text (sensitive) | `COUCH_DB_USER` + `COUCH_DB_PASSWORD`. |
| db | "Redis password?" | Free-text (sensitive) | `REDIS_PASSWORD`. |
| ai | "LLM setup?" | `AskUserQuestion`: `litellm-with-openai-key` / `litellm-local-ollama` / `none` | `LITELLM_MASTER_KEY` is the gate token. |
| storage | "Plugin directory?" | Optional bind mount | `PLUGINS_DIR` env + volume mount. Custom plugins live here. |
| offline | "Offline mode (no telemetry)?" | Boolean | `OFFLINE_MODE=1`. |
| tls | "Reverse proxy in front of Budibase's proxy?" | `AskUserQuestion`: `caddy` / `traefik` / `nginx` / `none-use-budibase-proxy-directly` | Budibase's internal proxy doesn't do TLS; needs external termination. |

## Install — Docker Compose (official)

Fetch upstream materials:

```bash
git clone https://github.com/Budibase/budibase.git
cd budibase/hosting

# OR without cloning:
mkdir budibase && cd budibase
curl -fsSLO https://raw.githubusercontent.com/Budibase/budibase/master/hosting/docker-compose.yaml
curl -fsSLO https://raw.githubusercontent.com/Budibase/budibase/master/hosting/hosting.properties
mv hosting.properties .env
```

Edit `.env` — the critical variables:

```bash
# hosting.properties / .env
MAIN_PORT=80

# SECRETS — generate with `openssl rand -hex 64`
JWT_SECRET=<random>
MINIO_ACCESS_KEY=<random>
MINIO_SECRET_KEY=<random>
INTERNAL_API_KEY=<random>
API_ENCRYPTION_KEY=<random>
COUCH_DB_USER=admin
COUCH_DB_PASSWORD=<random>
REDIS_PASSWORD=<random>
LITELLM_MASTER_KEY=<random>

# First admin user (created on first boot)
BB_ADMIN_USER_EMAIL=admin@example.com
BB_ADMIN_USER_PASSWORD=<admin-password>

# Environment
BUDIBASE_ENVIRONMENT=PRODUCTION

# Plugin directory (optional)
PLUGINS_DIR=/plugins

# Offline mode (no upstream telemetry)
OFFLINE_MODE=
```

Start the stack:

```bash
docker compose up -d
docker compose logs -f proxy-service
# → http://<host>:<MAIN_PORT>/
```

Log in with `BB_ADMIN_USER_EMAIL` / `BB_ADMIN_USER_PASSWORD`.

## hosting.properties (upstream-shipped env file)

Budibase ships `hosting.properties` (<https://github.com/Budibase/budibase/blob/master/hosting/hosting.properties>) as a convention for setting all env vars in one place. Rename to `.env` for Docker Compose to pick it up automatically.

## LiteLLM integration (AI agents)

LiteLLM is a proxy that presents a unified OpenAI-compatible API to 100+ model providers (OpenAI, Anthropic, Google, Azure OpenAI, AWS Bedrock, Ollama, HuggingFace, Together, Cohere, etc.). Budibase routes AI-agent LLM calls through LiteLLM.

Configuration:

```bash
# .env
LITELLM_MASTER_KEY=<random>                     # gate token — used by Budibase
OPENAI_API_KEY=sk-...                           # actual provider key
# OR
ANTHROPIC_API_KEY=sk-ant-...
# OR configure Ollama as a LiteLLM model in litellm config
```

For local Ollama models, mount a `litellm_config.yaml` into the `litellm-service` container specifying Ollama as a provider.

## Reverse proxy (Caddy example)

Budibase's internal `proxy-service` (nginx) serves HTTP on `${MAIN_PORT}` with NO TLS. For production:

```caddy
budibase.example.com {
    reverse_proxy proxy-service:10000
}
```

Set `PLATFORM_URL=https://budibase.example.com` in `.env` so Budibase generates correct public URLs in emails/auth flows.

## Plugins

Custom plugins (data sources, automation steps, components) can be uploaded via the admin UI OR dropped into the `PLUGINS_DIR`:

```yaml
# compose.yaml (fragment)
services:
  app-service:
    volumes:
      - ./plugins:/plugins
    environment:
      PLUGINS_DIR: /plugins
```

SDK: <https://github.com/Budibase/budibase/tree/master/packages/cli>. Prebuilt plugins: <https://github.com/Budibase/budibase-plugins>.

## Data layout

| Volume | Content |
|---|---|
| `couchdb_data` → `/opt/couchdb/data` | App metadata, users, roles, app definitions |
| `minio_data` → `/data` | Uploaded files, plugin binaries, internal-db attachments |
| `redis_data` → `/data` | Cache + job queue (rebuildable on restart) |
| `./plugins/` (optional) | Plugin binaries mounted into app-service + worker-service |

**Backup priority:**

1. **CouchDB data** — all app definitions + users. Back up via CouchDB's `_all_dbs` + per-DB export, OR tar the data dir while paused.
2. **MinIO data** — uploads + plugins. Tar while paused, OR use MinIO's `mc mirror` for live sync.
3. **`.env`** — all secrets. Store in a secret manager.
4. Redis — not worth backing up (cache only).

## Upgrade procedure

```bash
# Review release notes FIRST
# https://github.com/Budibase/budibase/releases

docker compose pull
docker compose up -d
docker compose logs -f app-service worker-service
```

App-service + worker-service run DB migrations on startup. Major version bumps (v2 → v3) have added schema changes — always back up CouchDB before upgrading.

## External databases (multi-tenant isolation)

For larger deployments, externalize CouchDB / MinIO / Redis to managed services (AWS DocumentDB for CouchDB alternatives, S3 for MinIO, ElastiCache for Redis). Kubernetes Helm chart supports this out of the box.

## Gotchas

- **SEVEN containers** — not a lightweight stack. Minimum 2 GB RAM, 10 GB disk for a small deploy. LiteLLM adds more.
- **The 5+ secrets must be generated and STABLE.** `JWT_SECRET`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `INTERNAL_API_KEY`, `API_ENCRYPTION_KEY` — rotating any of these after data has been written breaks existing sessions / encrypted-at-rest fields / MinIO access. Treat as one-way.
- **`hosting.properties` IS the source of truth** for envs. Copy to `.env`; don't edit both.
- **CouchDB is a weird choice if you've never used it.** It's a document DB (JSON blobs + map/reduce views). Budibase's app-metadata model fits it well. Backup via `pouchdb-dump` / `couchdb-backup` / file-system snapshot. Avoid direct manipulation.
- **MinIO browser is DISABLED in default compose** (`MINIO_BROWSER: "off"`). You can't log into MinIO's own UI without changing this. Useful for debugging; disable again after.
- **`proxy-service` (the internal nginx) is the ONLY container that exposes a port.** Everything else is internal. Don't try to port-forward app-service / worker-service directly — the proxy handles routing, cookies, websockets.
- **Proxy's default port inside container is 10000** (not 80). `${MAIN_PORT}:10000` in the compose maps your chosen port to 10000.
- **BB_ADMIN_USER_* creates the FIRST admin on initial boot only.** If you boot without these, use the web UI's first-time-setup wizard instead. If you change them later, they DO NOT rotate the existing admin's creds.
- **PLATFORM_URL must match how users access the instance.** If behind a reverse proxy, set to the public URL (https://budibase.example.com) — required for email password-reset links, OAuth callbacks.
- **Database connection strings are per-app.** Each Budibase app has its own datasources. A connection string you put in an app is NOT read from env vars at runtime (stored encrypted in CouchDB).
- **Multi-tenancy gotcha**: Budibase OSS is single-tenant by default. `ENABLE_ACCOUNT_PORTAL=0` keeps it single-tenant. For multi-tenant (each user has their own apps), use the Cloud or manage carefully.
- **LiteLLM provider keys** (OPENAI_API_KEY, ANTHROPIC_API_KEY, etc.) go in env vars OR a litellm config file. If in env, they're visible to anyone who can exec into the litellm container.
- **Offline mode (`OFFLINE_MODE=1`)** disables telemetry. Also disables the "check for updates" feature. Set for air-gapped / privacy-sensitive deploys.
- **Plugins are NOT sandboxed.** A malicious plugin has full code execution inside app-service. Only install plugins you trust.
- **Upgrading CouchDB major versions (2.x → 3.x)** across a Budibase upgrade requires manual CouchDB migration. Read CouchDB's own upgrade docs if that's in play.
- **Memory: app-service + worker-service can grow.** For large apps (100+ screens / many datasources), budget 1-2 GB each.
- **Auto-backup is not built-in.** Schedule your own via cron + `docker compose exec couchdb ...`.
- **The DigitalOcean 1-click** uses the same Docker stack — gets you running fast but isn't magic. You'll still need to configure env vars.
- **Helm chart's `values.yaml` is extensive.** Good defaults for K8s but requires reading <https://github.com/Budibase/budibase/blob/master/charts/budibase/values.yaml>.
- **"App" vs "Automation" in Budibase lingo** — an App is a UI on top of datasources; an Automation is a headless workflow triggered by events/schedules/webhooks. Both managed in the same builder.
- **GPL-3.0 license** is strong copyleft. Forking + redistributing = must release source. Self-hosting + modifying for internal use = fine.

## Links

- Upstream repo: <https://github.com/Budibase/budibase>
- Docs: <https://docs.budibase.com>
- Hosting methods overview: <https://docs.budibase.com/docs/hosting-methods>
- Docker Compose files: <https://github.com/Budibase/budibase/tree/master/hosting>
- Helm chart: <https://github.com/Budibase/budibase/tree/master/charts/budibase>
- DigitalOcean 1-click: <https://marketplace.digitalocean.com/apps/budibase>
- Budibase Cloud: <https://budibase.app>
- Plugin SDK: <https://github.com/Budibase/budibase/tree/master/packages/cli>
- Prebuilt plugins: <https://github.com/Budibase/budibase-plugins>
- Releases: <https://github.com/Budibase/budibase/releases>
- Discussions: <https://github.com/Budibase/budibase/discussions>
- LiteLLM (LLM proxy): <https://github.com/BerriAI/litellm>
- CouchDB docs (upstream dependency): <https://docs.couchdb.org>
