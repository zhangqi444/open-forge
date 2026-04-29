---
name: twenty-crm-project
description: Twenty recipe for open-forge. AGPLv3-licensed open-source CRM — modern Salesforce/HubSpot alternative with customizable objects, GraphQL/REST API, workflows, Gmail/Outlook calendar+email sync. Stack is a Node/TypeScript server + NestJS + React frontend backed by Postgres + Redis + optional S3 storage. Canonical self-host is Docker Compose (upstream-provided at `packages/twenty-docker/docker-compose.yml`). Covers Compose install, SSL reverse-proxy, SMTP/S3/OAuth wiring, the mandatory `APP_SECRET` bootstrap, and the major "SERVER_URL mismatch breaks logins" footgun.
---

# Twenty

AGPLv3 open-source CRM, modeled as a modern replacement for Salesforce / HubSpot / Pipedrive. Upstream: <https://github.com/twentyhq/twenty>. Docs: <https://twenty.com/developers>.

Stack:

- **server** — NestJS (Node.js/TypeScript) GraphQL + REST API
- **worker** — background jobs (emails, sync, webhooks) using BullMQ on Redis
- **db** — Postgres 16+
- **redis** — cache + queue broker
- **(optional)** S3-compatible object storage for file uploads
- Frontend React app bundled into the same `twentycrm/twenty:<tag>` image, served by the server

**AGPLv3 obligation:** if you modify Twenty and offer it as a network-accessible service (SaaS), you must publish the modified source to its users. Running stock Twenty for your company's internal use = no publication obligation.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (`packages/twenty-docker/docker-compose.yml`) | <https://docs.twenty.com/developers/self-host/capabilities/docker-compose> | ✅ Recommended | The upstream-blessed self-host path. |
| Local dev setup (`yarn nx start`) | <https://docs.twenty.com/developers/contribute/capabilities/local-setup> | ✅ Dev only | Monorepo with Yarn + Node 22. Not for production. |
| Terraform — AWS | <https://docs.twenty.com/developers/self-host/capabilities/terraform-aws> | ✅ | AWS ECS deployment. |
| Kubernetes | <https://docs.twenty.com/developers/self-host/capabilities/kubernetes> | ✅ | Helm chart via upstream docs. |
| Railway / Render / Sevalla (1-click) | Per-platform marketplace | ⚠️ Third-party but linked by upstream | Managed PaaS. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| preflight | "Twenty version (image tag)?" | Free-text, default `latest`; check <https://github.com/twentyhq/twenty/releases> for stable tags | Pinned tag strongly recommended. |
| domain | "Public URL (e.g. `https://crm.example.com`)?" | Free-text | Goes into `SERVER_URL`. **Must match exactly** what users type into their browser — protocol and port included. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | Twenty itself does not do TLS. |
| secrets | "`APP_SECRET` value?" | Free-text (sensitive) — `openssl rand -base64 32` | **MANDATORY.** The default literal `replace_me_with_a_random_string` leaks if not changed. |
| db | "Postgres password?" | Free-text (sensitive) | `PG_DATABASE_PASSWORD`. |
| storage | "Storage backend? (local / s3)" | `AskUserQuestion` | `STORAGE_TYPE`. S3 recommended for anything durable. |
| smtp | "SMTP host/port/user/pass/from?" | Free-text | `EMAIL_SMTP_*` — required for sign-up confirmations, password resets, workspace invites. |
| auth | "Google OAuth? (optional)" | Free-text for `AUTH_GOOGLE_CLIENT_ID` / `AUTH_GOOGLE_CLIENT_SECRET` | Needed for Gmail/Google Calendar sync feature. |
| auth | "Microsoft OAuth? (optional)" | Free-text for `AUTH_MICROSOFT_*` | Needed for Outlook/MS Calendar sync. |

## Install — Docker Compose

### 1. Fetch upstream compose + env files

```bash
mkdir -p /opt/twenty && cd /opt/twenty

# Canonical compose (from the monorepo's packages/twenty-docker/ dir)
curl -o docker-compose.yml \
  https://raw.githubusercontent.com/twentyhq/twenty/main/packages/twenty-docker/docker-compose.yml

curl -o .env.example \
  https://raw.githubusercontent.com/twentyhq/twenty/main/packages/twenty-docker/.env.example

cp .env.example .env
```

### 2. Edit `.env`

```bash
# Minimum required for a working deploy:
TAG=latest   # pin to a specific version in production, e.g. TAG=v0.58.0

SERVER_URL=https://crm.example.com

APP_SECRET=<openssl rand -base64 32>

# Defaults to postgres/postgres — change for non-localhost deploys
PG_DATABASE_USER=postgres
PG_DATABASE_PASSWORD=<strong-random>
# PG_DATABASE_HOST/PORT only needed if using external DB

STORAGE_TYPE=local  # or `s3`
# If s3:
# STORAGE_S3_REGION=us-east-1
# STORAGE_S3_NAME=twenty-storage
# STORAGE_S3_ENDPOINT=
# STORAGE_S3_ACCESS_KEY_ID=
# STORAGE_S3_SECRET_ACCESS_KEY=

# Email — uncomment in compose environment block + set here
# EMAIL_FROM_ADDRESS=no-reply@example.com
# EMAIL_FROM_NAME="Twenty CRM"
# EMAIL_DRIVER=smtp
# EMAIL_SMTP_HOST=smtp.example.com
# EMAIL_SMTP_PORT=587
# EMAIL_SMTP_USER=<smtp-user>
# EMAIL_SMTP_PASSWORD=<smtp-password>
```

Generate `APP_SECRET`:

```bash
openssl rand -base64 32
```

### 3. Bring it up

```bash
docker compose up -d
docker compose logs -f server
# → Wait for "Twenty server started on port 3000"
docker compose logs -f worker
# → Worker should be processing BullMQ queues
```

Visit `https://crm.example.com` (via your reverse proxy) — the first sign-up creates the workspace owner account.

## Reverse proxy (Caddy example)

```caddy
crm.example.com {
    reverse_proxy 127.0.0.1:3000
}
```

For nginx, proxy `/` to `http://127.0.0.1:3000` with WebSocket upgrade headers (Twenty uses GraphQL subscriptions + BullMQ dashboard WS):

```nginx
location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 300s;
    client_max_body_size 100M;   # for file uploads
}
```

## Post-install — enabling features

### Email sync (Gmail / Outlook)

Twenty can suck in the user's email history and show it inline next to CRM contacts. Requires:

1. Google Cloud Console project with OAuth 2.0 credentials, redirect URI = `https://crm.example.com/auth/google-apis/get-access-token`. Set:
   ```
   MESSAGING_PROVIDER_GMAIL_ENABLED=true
   CALENDAR_PROVIDER_GOOGLE_ENABLED=true
   AUTH_GOOGLE_CLIENT_ID=<from Google Cloud>
   AUTH_GOOGLE_CLIENT_SECRET=<from Google Cloud>
   AUTH_GOOGLE_CALLBACK_URL=https://crm.example.com/auth/google/redirect
   AUTH_GOOGLE_APIS_CALLBACK_URL=https://crm.example.com/auth/google-apis/get-access-token
   ```

2. For Microsoft: analogous OAuth creds from Azure Portal, `AUTH_MICROSOFT_*` vars.

3. **Uncomment these vars in the compose `environment` block** — they ship commented out. Editing only `.env` is NOT enough; the compose needs to reference them.

### Workspace admin features

There's no central "superadmin" over multiple workspaces in OSS Twenty. Each workspace owner administers their own workspace via the in-app Settings. Workspace isolation is at the database level (shared Postgres, workspace-scoped schemas).

## Data layout

| Location | Content |
|---|---|
| Named volume `server-local-data` | `STORAGE_TYPE=local` uploads. Lost if volume is wiped. Migrate to S3 for durability. |
| Named volume `db-data` | Postgres data dir. |
| Named volume `redis-data` | Redis AOF persistence. |

**Backups = dump Postgres + snapshot `server-local-data` (or S3 bucket versioning if on S3).**

```bash
# Postgres dump
docker compose exec db pg_dump -U postgres default > backup-$(date +%F).sql

# Uploads (local mode)
docker run --rm -v twenty_server-local-data:/data -v $(pwd):/backup busybox \
  tar czf /backup/uploads-$(date +%F).tar.gz -C /data .
```

## Upgrade procedure

Twenty is pre-v1.0 and iterates fast (weekly-ish releases). Upgrade rigor matters.

```bash
# 1. Back up DB + uploads + .env
docker compose exec db pg_dump -U postgres default > backup-pre-upgrade.sql

# 2. Check release notes — https://github.com/twentyhq/twenty/releases
#    Pre-1.0 breaking changes happen; schema migrations run automatically on server boot
#    but read them to know what's changing.

# 3. Update TAG in .env (or edit docker-compose.yml directly)
sed -i 's/^TAG=.*/TAG=v0.59.0/' .env

# 4. Pull + recreate
docker compose pull
docker compose up -d

# 5. Watch server logs — migration runs at server startup
docker compose logs -f server | head -100
```

**Both `server` and `worker` containers must run the same image tag.** The worker has `DISABLE_DB_MIGRATIONS=true` set in compose (server runs them); if the two disagree on schema expectations, workers will throw at runtime.

## Configuration reference

Selected env vars, full list at <https://docs.twenty.com/developers/self-host/capabilities/docker-compose#environment-variables>:

| Var | Purpose |
|---|---|
| `SERVER_URL` | Canonical public URL. Must match what users paste in browser. Used for CORS, OAuth callbacks, and email links. |
| `APP_SECRET` | JWT signing key. Rotating invalidates all existing sessions. |
| `PG_DATABASE_URL` | Full Postgres DSN (overrides individual `PG_*` vars). |
| `REDIS_URL` | Redis DSN. |
| `STORAGE_TYPE` | `local` or `s3`. |
| `DISABLE_DB_MIGRATIONS` | `true` on the worker; never set on server in normal operation. |
| `DISABLE_CRON_JOBS_REGISTRATION` | Same — workers don't register crons. |
| `SIGN_IN_PREFILLED` | `true` prefills demo creds on sign-in page. Leave `false` in production. |
| `IS_SIGN_UP_DISABLED` | `true` locks down sign-ups to admin invitations only. Set this after creating your admin account. |
| `FRONT_BASE_URL` | Usually same as `SERVER_URL` but separable for split frontend deploys. |

## Gotchas

- **`SERVER_URL` must match exactly** what users type into their browser — including protocol (`https://` vs `http://`), domain, and port if non-default. Mismatch breaks CORS, OAuth, and email links in subtle ways. Symptom: "things work on localhost but login loops on the real domain."
- **Default `APP_SECRET` is a literal placeholder string.** The compose default is `replace_me_with_a_random_string`. If you don't set it, sessions are trivially forgeable. Set with `openssl rand -base64 32`.
- **OAuth vars are commented-out by default in compose.** Copying values into `.env` does nothing if the `environment:` block in `docker-compose.yml` doesn't reference them. Uncomment the ones you need.
- **Server + worker must be same image tag.** Mixing versions → silent data corruption or "column does not exist" errors.
- **File uploads default to local named volume.** That volume is tied to the host. Moving between hosts or losing the host = lost files. Switch to S3 (`STORAGE_TYPE=s3`) for anything you care about.
- **Pre-1.0 schema churn.** Major features still rework database structure between releases. Back up before every upgrade; don't skip versions (upgrade 0.55 → 0.56 → 0.57, not 0.55 → 0.57).
- **No "disable new workspace sign-ups" out of the box at workspace-admin level.** The instance-wide toggle is `IS_SIGN_UP_DISABLED=true` — set this after you've created your workspace, otherwise anyone visiting your URL can create another workspace on your instance.
- **Worker failures are silent-ish.** Background jobs (email sync, calendar sync) failing show up as "no new data" in the UI, not loud errors. `docker compose logs -f worker` is your friend.
- **BullMQ dashboard is not exposed by default.** If you need to inspect queues, add a Bull Board container or port-forward Redis.
- **GraphQL + REST are both exposed on the same port.** `/graphql` and `/rest/*` share `:3000`. Rate-limit at reverse proxy if exposing publicly.
- **Postgres version upgrade is NOT automatic.** If you bump Postgres major (e.g. 15 → 16), you need to pg_dump from the old container and restore into the new one. Twenty's upgrade path doesn't touch Postgres itself.
- **AGPLv3 means SaaS operators must publish modifications.** If you fork Twenty and host the fork for other users, that fork's source must be publishable (link from the UI). For internal-only use, this doesn't bite.

## Links

- Upstream repo: <https://github.com/twentyhq/twenty>
- Developer docs: <https://twenty.com/developers>
- Self-hosting index: <https://docs.twenty.com/developers/self-host>
- Docker Compose guide: <https://docs.twenty.com/developers/self-host/capabilities/docker-compose>
- Env var reference: <https://docs.twenty.com/developers/self-host/capabilities/docker-compose#environment-variables>
- Releases: <https://github.com/twentyhq/twenty/releases>
- Docker image: <https://hub.docker.com/r/twentycrm/twenty>
- Discord: <https://discord.gg/cx5n4Jzs57>
