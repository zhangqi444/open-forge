---
name: novu-project
description: Novu recipe for open-forge. Apache-2.0 open-source notification infrastructure — orchestrates email / SMS / push / chat / in-app notifications from one API across 50+ providers. Self-hosted as a multi-service Docker Compose stack (API + worker + web + WS + embed + widget + Mongo + Redis + localstack S3). Pre-3.x upstream rewrites have been frequent; self-host lags cloud. This recipe covers the upstream community Docker Compose, the mandatory `JWT_SECRET` / `NOVU_SECRET_KEY` / `STORE_ENCRYPTION_KEY` bootstrap, MongoDB+Redis requirement, the `HOST_NAME` / reverse-proxy wiring, and the cloud-vs-self-hosted feature gap.
---

# Novu

Apache-2.0 open-source notification infrastructure. Upstream: <https://github.com/novuhq/novu>. Docs: <https://docs.novu.co>. Self-host quickstart: <https://docs.novu.co/community/self-hosting-novu>.

Novu is a notification API that sits between your app and notification providers (SendGrid, Twilio, FCM, Slack, Discord, etc.). You send one API call with a subscriber ID + workflow name; Novu orchestrates delivery across channels (email / SMS / push / chat / in-app), handles templates, digest / delay, and tracks delivery state.

## Self-host vs Novu Cloud

Self-hosted Novu runs the OSS core:

- **API + worker + web (Studio) + websocket gateway** — all OSS.
- **`novu/embed` + in-app widget backend** — OSS.
- **50+ provider integrations** — OSS.

Novu Cloud adds (not in self-host):

- Managed infra / autoscaling / backups
- Novu Inbox (v3) newer features land on cloud first; self-host typically lags 1-2 minor versions
- SLA + support

The OSS code is genuine Apache-2.0, no BSL / commons-clause. Self-host is fully functional for sending notifications; the gap is mostly operational polish and feature recency.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (`docker/community`) | <https://github.com/novuhq/novu/tree/next/docker/community> | ✅ Recommended | Upstream-blessed self-host path. Multi-service stack. |
| Kubernetes / Helm | Community charts | ⚠️ Community | Upstream acknowledges Helm charts exist but not officially maintained. |
| Source build (monorepo) | `pnpm install && pnpm start` | ✅ | Dev only — 100+ package monorepo, not an install path. |

## Architecture (what you're deploying)

The community compose brings up ~8 services:

| Service | Port | Role |
|---|---|---|
| `mongodb` | 27017 | Primary DB (notifications, subscribers, workflows, messages). |
| `redis` | 6379 | Cache + BullMQ queues. |
| `api` | 3000 | REST API — where you POST `/v1/events/trigger`. |
| `worker` | 3004 | Consumes queues, fans out to provider SDKs. |
| `ws` | 3002 | WebSocket gateway for in-app inbox / real-time updates. |
| `web` | 4200 | Admin Studio UI. |
| `embed` | 4701 | JS widget loader for in-app notifications. |
| `widget` | 4500 | Widget backend. |
| `localstack` | 4566 | Local S3-compatible storage (ephemeral — replace with real S3 for production). |

Minimum RAM: ~2 GB for a test deploy; 4+ GB recommended for anything beyond dev.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `k8s` | Docker Compose is the only upstream-supported path. |
| secrets | "Generate `JWT_SECRET`?" | Auto: `openssl rand -hex 32` | **REQUIRED** — 32-byte hex. |
| secrets | "Generate `NOVU_SECRET_KEY`?" | Auto: `openssl rand -hex 32` | **REQUIRED** — 32-byte hex. |
| secrets | "Generate `STORE_ENCRYPTION_KEY`?" | Auto: `openssl rand -hex 16` | **REQUIRED** — **exactly 32 characters**. Wrong length = silent provider-credential decryption failures later. |
| secrets | "MongoDB root password?" | Free-text (sensitive) | Set `MONGO_INITDB_ROOT_PASSWORD`. |
| dns | "Public host for Novu?" | Free-text, e.g. `https://novu.example.com` | Sets `HOST_NAME`. Without HTTPS + correct host, Studio loads but API calls from the browser CORS-fail. |
| tls | "Reverse proxy (Caddy / nginx / Traefik)?" | `AskUserQuestion` | Novu doesn't terminate TLS. |
| storage | "S3 backend for attachments? (localstack-dev / real-S3 / skip)" | `AskUserQuestion` | Default compose uses localstack (ephemeral — attachments lost on container restart). Swap to real S3/R2/MinIO for anything persistent. |
| providers | "Which delivery providers to wire up later?" | Multi-select, deferred | SendGrid / Mailgun / Twilio / FCM / APNs / Slack / Discord / generic SMTP — configured inside Studio after boot, not at install time. |

## Install — Docker Compose (upstream-recommended)

```bash
git clone https://github.com/novuhq/novu.git --depth 1
cd novu/docker/community

# 1. Copy + fill env
cp .env.example .env
# Edit .env — the REQUIRED fields:
#   JWT_SECRET=<openssl rand -hex 32>
#   STORE_ENCRYPTION_KEY=<openssl rand -hex 16>   # MUST be 32 chars (hex of 16 bytes)
#   NOVU_SECRET_KEY=<openssl rand -hex 32>
#   MONGO_INITDB_ROOT_USERNAME=root
#   MONGO_INITDB_ROOT_PASSWORD=<strong password>
#   HOST_NAME=https://novu.example.com        # your public URL

# 2. Bring up the stack
docker compose up -d
docker compose ps
docker compose logs -f api worker web

# 3. Wait ~1-2 minutes for DB migration + worker boot, then:
# Open Studio at http://<host>:4200 (behind reverse proxy: https://novu.example.com)
# First signup becomes the instance owner.
```

### One-liner secret generator

```bash
cat > .env <<EOF
$(cat .env.example | sed \
  -e "s|^JWT_SECRET=.*|JWT_SECRET=$(openssl rand -hex 32)|" \
  -e "s|^STORE_ENCRYPTION_KEY=.*|STORE_ENCRYPTION_KEY=$(openssl rand -hex 16)|" \
  -e "s|^NOVU_SECRET_KEY=.*|NOVU_SECRET_KEY=$(openssl rand -hex 32)|" \
  -e "s|^MONGO_INITDB_ROOT_PASSWORD=.*|MONGO_INITDB_ROOT_PASSWORD=$(openssl rand -hex 24)|")
EOF
```

## Reverse proxy wiring

Novu exposes 5 web-facing ports. Either map them all to subdomains, OR use path-based routing on one domain (trickier — Studio is a Vue SPA and needs rewrite rules).

### Subdomain approach (recommended, Caddy example)

```caddy
novu.example.com {
    reverse_proxy web:4200
}

api.novu.example.com {
    reverse_proxy api:3000
}

ws.novu.example.com {
    reverse_proxy ws:3002
}

widget.novu.example.com {
    reverse_proxy widget:4500
}

embed.novu.example.com {
    reverse_proxy embed:4701
}
```

Set matching env vars in `.env` so Studio knows the public URLs:

```
API_ROOT_URL=https://api.novu.example.com
VITE_API_HOSTNAME=https://api.novu.example.com
VITE_WEBSOCKET_HOSTNAME=https://ws.novu.example.com
FRONT_BASE_URL=https://novu.example.com
HOST_NAME=https://novu.example.com
```

After `.env` changes, `docker compose up -d --force-recreate`.

## Data layout

| Service | Named volume | Content |
|---|---|---|
| `mongodb` | `mongodb` | Everything — workflows, subscribers, notifications, messages, API keys. **This is the critical backup target.** |
| `redis` | (ephemeral in default compose) | Queues + cache. Safe to lose; workers re-fetch pending jobs from Mongo. |
| `localstack` | (ephemeral) | Dev-only S3. Replace with real S3 for production attachments. |

### Backup

```bash
# MongoDB dump
docker compose exec mongodb sh -c \
  'mongodump --username=$MONGO_INITDB_ROOT_USERNAME --password=$MONGO_INITDB_ROOT_PASSWORD \
    --authenticationDatabase=admin --archive' > novu-$(date +%F).dump

# Restore
docker compose exec -T mongodb sh -c \
  'mongorestore --username=$MONGO_INITDB_ROOT_USERNAME --password=$MONGO_INITDB_ROOT_PASSWORD \
    --authenticationDatabase=admin --archive' < novu-YYYY-MM-DD.dump
```

**Secrets must be backed up separately + alongside the dump.** Losing `STORE_ENCRYPTION_KEY` = every stored provider credential becomes undecryptable, even with a full DB restore. Put it in a password manager the day you generate it.

## Upgrade procedure

```bash
cd novu/docker/community
git pull origin next                         # pull upstream compose + env changes
docker compose pull                          # new images
docker compose up -d                         # start — migrations run automatically on api boot

# Check migration output:
docker compose logs api | grep -iE 'migration|migrate'
```

**Read the release notes** at <https://github.com/novuhq/novu/releases> before every upgrade. Novu has had multiple major-version breaks (v0.x → v1.x → v2.x → v3.x) each with their own migration story.

## Gotchas

- **`STORE_ENCRYPTION_KEY` must be EXACTLY 32 characters.** Upstream's env template shows `openssl rand -hex 16` (which produces 32 hex chars). Set it longer or shorter and Novu starts, but provider credentials fail to decrypt later with opaque errors. Validate: `echo -n "$STORE_ENCRYPTION_KEY" | wc -c` → must print `32`.
- **Losing `STORE_ENCRYPTION_KEY` = data loss.** Even with a MongoDB backup, rotated keys make stored integration creds un-decryptable. Back this key up OUT OF BAND on day one.
- **MongoDB replica set NOT required** (Novu uses standalone Mongo), unlike Rocket.Chat. If you're migrating from an old blog post that set up `rs.initiate()`, you don't need to.
- **Self-host lags cloud.** Expect a 1-2 minor-version delay between Novu Cloud features and the OSS release. New features often land as "experimental" flags in OSS first. Check the release notes — don't assume parity.
- **localstack is dev-only.** The default compose uses localstack as an S3 stand-in for attachments. Restart = data loss. Swap to real S3 / MinIO / R2 before running notifications with attachments.
- **`HOST_NAME` without trailing slash.** The env loads expects `https://novu.example.com` not `https://novu.example.com/`. Trailing slash breaks Studio's API URL derivation.
- **5 public ports = 5 CORS surfaces.** Every subdomain needs its own CORS-origin allowlist configured through `.env` or Studio. CORS errors at boot are nearly always because one of `API_ROOT_URL` / `VITE_API_HOSTNAME` / `FRONT_BASE_URL` / `HOST_NAME` points at a host the browser can't actually reach.
- **Worker crash loop = queue backup.** If the worker container crashes (OOM, provider SDK bug), Redis queues pile up. Watch `docker compose logs worker` for the first error after bringing up a new provider.
- **MongoDB 8.0.x in default compose.** Older self-host guides pin 4.4 / 5.0 — check the compose on the `next` branch when following outside docs. Upgrading Mongo major versions across containers is non-trivial.
- **Bridge vs. legacy triggers.** Novu v2+ introduced "Bridge" (code-first workflows). v1 in-DB workflows still work but are being phased out. New deploys should use Bridge + the `@novu/framework` SDK.
- **Provider credentials stored encrypted-at-rest** in Mongo, but TLS at the provider integration layer is YOUR responsibility — Novu uses whatever the provider SDK defaults to.
- **"Community" vs "EE" distinction is historical.** All current OSS code is Apache-2.0. The `-ee` packages that existed in early commits have been merged or dropped.

## Links

- Upstream repo: <https://github.com/novuhq/novu>
- Self-host guide: <https://docs.novu.co/community/self-hosting-novu>
- Self-host compose: <https://github.com/novuhq/novu/tree/next/docker/community>
- Environment variables: <https://docs.novu.co/platform/deployment/environment-variables>
- Providers catalog: <https://docs.novu.co/integrations/providers/overview>
- Framework SDK (Bridge): <https://docs.novu.co/framework/overview>
- Discord: <https://discord.novu.co>
- Releases: <https://github.com/novuhq/novu/releases>
