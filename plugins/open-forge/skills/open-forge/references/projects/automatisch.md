---
name: Automatisch
description: Open-source Zapier / Make.com alternative. Visual workflow builder that connects apps via triggers + actions. Node.js + Postgres + Redis + BullMQ for job queue. AGPL-3.0 (CE) / commercial (EE).
---

# Automatisch

Automatisch is a self-hostable Zapier alternative: pick a trigger ("new row in Google Sheets", "new GitHub issue", "scheduled time"), chain actions ("send Slack message", "create Trello card", "HTTP request"), and Automatisch runs the flow whenever the trigger fires. 50+ built-in integrations; custom JavaScript steps for anything else.

Good fit for:

- Self-hosters who want workflow automation without sending data to Zapier/Make
- GDPR-sensitive automations (internal-only data flows)
- Teams that want to self-host as a shared tool

Note: **commercial dual-licensing**. Community Edition is AGPL-3.0 and missing a few enterprise features (SSO, RBAC, audit log, etc.).

- Upstream repo: <https://github.com/automatisch/automatisch>
- Website: <https://automatisch.io>
- Docs: <https://automatisch.io/docs>
- Install docs: <https://automatisch.io/docs/installation/docker>
- Cloud (hosted): <https://automatisch.io/pricing>

## Architecture in one minute

Four components:

1. **`main`** — Node.js web/API server on port 3000
2. **`worker`** — same image, same code, but runs background job workers (`WORKER=true`)
3. **`postgres`** (14.5) — main DB
4. **`redis`** (7.0.4) — BullMQ job queue backing

Both `main` and `worker` run the same Docker image with a different env var. Stateless; scale horizontally.

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                                  |
| ----------- | ---------------------------------------------------- | ---------------------------------------------------------------------- |
| Single VM   | Docker Compose (`docker-compose.yml` from repo)      | **Recommended** — upstream-maintained                                    |
| Single VM   | Docker run with Postgres + Redis elsewhere            | Same image; pass env vars                                                |
| Kubernetes  | Helm chart (community)                                | Not upstream-maintained; build from compose                              |
| Managed     | automatisch.io cloud                                  | SaaS tier                                                                |

## Inputs to collect

| Input                    | Example                                    | Phase     | Notes                                                                |
| ------------------------ | ------------------------------------------ | --------- | -------------------------------------------------------------------- |
| `HOST` + `PROTOCOL` + `PORT` | `automatisch.example.com` / `https` / `443` | Runtime  | Used in OAuth callbacks — **permanent**; flows break if changed      |
| Postgres                 | 14 (compose uses 14.5)                     | DB        | v14+ supported                                                        |
| Redis                    | 7.x                                        | Queue     | For BullMQ                                                            |
| `ENCRYPTION_KEY`         | `openssl rand -hex 32`                     | Security  | **Critical** — encrypts stored OAuth tokens for integrations          |
| `WEBHOOK_SECRET_KEY`     | `openssl rand -hex 32`                     | Security  | Signs outgoing webhook URLs                                           |
| `APP_SECRET_KEY`         | `openssl rand -hex 32`                     | Security  | JWT signing                                                           |
| Admin account            | first registration = admin                 | Bootstrap | Via `/login` after first start                                        |
| SMTP                     | optional                                   | Email     | For password reset + notifications                                    |

## Install via Docker Compose

From <https://github.com/automatisch/automatisch/blob/main/docker-compose.yml>:

```yaml
services:
  main:
    image: automatischio/automatisch:latest    # pin a version in prod
    ports: ['3000:3000']
    depends_on:
      postgres: { condition: service_healthy }
      redis:    { condition: service_started }
    environment:
      - HOST=automatisch.example.com
      - PROTOCOL=https
      - PORT=3000
      - APP_ENV=production
      - REDIS_HOST=redis
      - POSTGRES_HOST=postgres
      - POSTGRES_DATABASE=automatisch
      - POSTGRES_USERNAME=automatisch_user
      - POSTGRES_PASSWORD=<strong>
      - ENCRYPTION_KEY=<openssl rand -hex 32>
      - WEBHOOK_SECRET_KEY=<openssl rand -hex 32>
      - APP_SECRET_KEY=<openssl rand -hex 32>
    volumes:
      - automatisch_storage:/automatisch/storage
    restart: unless-stopped

  worker:
    image: automatischio/automatisch:latest    # same image!
    depends_on: [main]
    environment:
      - APP_ENV=production
      - REDIS_HOST=redis
      - POSTGRES_HOST=postgres
      - POSTGRES_DATABASE=automatisch
      - POSTGRES_USERNAME=automatisch_user
      - POSTGRES_PASSWORD=<strong>
      - ENCRYPTION_KEY=<same as main>
      - WEBHOOK_SECRET_KEY=<same as main>
      - APP_SECRET_KEY=<same as main>
      - WORKER=true             # flips the image into worker mode
    volumes:
      - automatisch_storage:/automatisch/storage
    restart: unless-stopped

  postgres:
    image: postgres:14.5
    environment:
      - POSTGRES_DB=automatisch
      - POSTGRES_USER=automatisch_user
      - POSTGRES_PASSWORD=<strong>
    volumes: [postgres_data:/var/lib/postgresql/data]
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}']
      interval: 10s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7.0.4
    volumes: [redis_data:/data]
    restart: unless-stopped

volumes:
  automatisch_storage:
  postgres_data:
  redis_data:
```

Note: the upstream `docker-compose.yml` uses `build:` (building from source). The image-based form above uses the published `automatischio/automatisch` image from <https://hub.docker.com/r/automatischio/automatisch>. Pin a version tag in prod.

### First boot

1. `docker compose up -d`
2. Watch `docker compose logs -f main` — initial run runs migrations (takes 30s)
3. Browse `https://automatisch.example.com` → **Sign up** → first user becomes admin
4. Configure OAuth integrations under **Apps** (Google, GitHub, Slack, etc. — each needs its own OAuth credentials)

## Data & config layout

- `automatisch_storage` volume — uploaded files (for "HTTP" trigger uploads, attachments in actions)
- `postgres_data` volume — users, connections, flows, execution history, step results
- `redis_data` volume — job queue (BullMQ); can be lost without data corruption (in-flight jobs redelivered)

**Stored OAuth tokens are encrypted with `ENCRYPTION_KEY`**. Losing the key = losing all connections = every flow needs reauthorization.

## Backup

```sh
# DB (contains everything important)
docker compose exec -T postgres pg_dump -U automatisch_user automatisch | gzip > automatisch-db-$(date +%F).sql.gz

# Storage (uploaded files)
docker run --rm -v automatisch_storage:/src -v "$PWD":/backup alpine \
  tar czf /backup/automatisch-storage-$(date +%F).tgz -C /src .

# SECRETS — back these up separately, SECURELY
echo "ENCRYPTION_KEY=..."  > automatisch-secrets-$(date +%F).env
echo "WEBHOOK_SECRET_KEY=..." >> automatisch-secrets-$(date +%F).env
echo "APP_SECRET_KEY=..." >> automatisch-secrets-$(date +%F).env
```

**Backup is useless without the three secret keys.** If you restore the DB but rotated `ENCRYPTION_KEY`, all stored OAuth tokens become unusable.

## Upgrade

1. Releases: <https://github.com/automatisch/automatisch/releases>.
2. `docker compose pull && docker compose up -d`. Both `main` and `worker` should use the same tag.
3. Migrations run automatically on `main` startup; `worker` waits.
4. **Read release notes for breaking changes.** Automatisch is pre-1.0 (as of writing); occasionally breaks API or flow schema.
5. Major Postgres upgrades (14 → 16): backup + restore; no in-place.

## Gotchas

- **Pre-1.0 software.** Breaking changes land in minor versions. Pin a version, test upgrades on a staging copy, read release notes.
- **First user = admin.** Race condition: bring up on a private network, sign up, THEN expose. Or use the `createUser` CLI if the version you're on supports it.
- **`HOST` + `PROTOCOL` are baked into OAuth callback URLs** you register at Google/GitHub/etc. Changing them = every integration must be re-registered + reauthorized.
- **`ENCRYPTION_KEY` loss = data loss for credentials.** All connected-app OAuth tokens become ciphertext garbage. Back it up separately from the DB.
- **`main` and `worker` must share the same secrets.** Different keys = jobs picked up by worker can't decrypt the connection creds; flows fail silently.
- **`POSTGRES_PASSWORD` in the example compose is `automatisch_password`.** Change it BEFORE first start.
- **Community Edition vs Enterprise.** CE is AGPL-3.0 and missing SSO, RBAC, audit logs, multi-tenant. Some features gated at runtime — if you see "Pro only", that's the split.
- **Integration OAuth credentials** (Google client_id/secret, Slack app, etc.) you supply per integration — not provided by Automatisch. Setup per app from <https://automatisch.io/docs/apps>.
- **Flow execution history** grows unbounded by default. Enable retention settings or prune `execution_steps` table periodically.
- **Webhooks receive POSTs at `/webhooks/<flow-id>`.** Public endpoint — protect with `WEBHOOK_SECRET_KEY` signature validation in the flow.
- **Custom code step** runs untrusted user JS in a sandboxed-ish context (vm2/isolated-vm depending on version). Don't expose to untrusted users without additional confinement.
- **Redis password not set in upstream compose.** Fine inside docker network; add `requirepass` if Redis is exposed.
- **Scaling workers:** add more `worker` replicas (`docker compose up -d --scale worker=4`). Queue is shared via Redis.
- **Long-running flows** can time out. Tune BullMQ job timeout via env (varies per version; check `packages/backend/src/config.js`).
- **Mobile app:** none. Web UI only.
- **AGPL-3.0 network copyleft.** Running a modified Automatisch as a SaaS requires offering source.
- **Alternatives worth knowing:**
  - **n8n** — larger community, AGPL + commercial, more integrations, heavier
  - **Activepieces** — similar scope, MIT (open-core)
  - **Huginn** — Ruby, long-established, less polished UI
  - **Node-RED** — flow-based programming, not as "Zapier-shaped"
  - **Windmill** — workflow + script runner; more dev-focused
  - **Apache Airflow** — for scheduled DAGs, not "trigger/action" automation

## Links

- Repo: <https://github.com/automatisch/automatisch>
- Docs: <https://automatisch.io/docs>
- Docker install: <https://automatisch.io/docs/installation/docker>
- Apps / integrations: <https://automatisch.io/docs/apps>
- Configuration: <https://automatisch.io/docs/configuration>
- Releases: <https://github.com/automatisch/automatisch/releases>
- Docker Hub: <https://hub.docker.com/r/automatischio/automatisch>
- Pricing (cloud): <https://automatisch.io/pricing>
- Licensing: <https://automatisch.io/licensing>
- Community Discord: <https://automatisch.io/discord>
