---
name: postiz-project
description: Postiz recipe for open-forge. AGPL-3.0 self-hosted social-media post scheduling platform — alternative to Buffer / Hypefury / Typefully. Supports Twitter/X, LinkedIn, Reddit, Instagram, Facebook, YouTube, TikTok, Pinterest, Threads, Bluesky, Mastodon, Discord, Slack, Dribbble. AI features for post generation, calendar UI, analytics, team collaboration, public API (N8N / Make / Zapier), Chrome extension for cookie-based platforms like Skool. Tech stack heavy — NextJS + NestJS + Postgres + Redis + Temporal (workflow engine) + ElasticSearch (for Temporal). Requires obtaining OAuth credentials from each social platform. Covers the official Docker Compose stack, env-var reference, short-link service integrations, and the sharp-edges of the multi-service architecture.
---

# Postiz

AGPL-3.0 self-hosted social media scheduler. Upstream: <https://github.com/gitroomhq/postiz-app>. Docs: <https://docs.postiz.com>. Hosted service: <https://postiz.com>.

Think Buffer / Hypefury but fully self-hostable. Write a post once → schedule to all your connected platforms → track analytics → invite teammates to collaborate. Postiz includes AI-assisted post generation, a calendar view, post previews per platform, and a growing list of supported networks.

## Supported platforms (publish targets)

At the time of writing (2026-04):

- **X (Twitter)**, **LinkedIn**, **Reddit**, **Instagram**, **Facebook**, **YouTube**, **TikTok**, **Pinterest**, **Threads**, **Bluesky**, **Mastodon**, **Discord**, **Slack**, **Dribbble**
- Plus newsletters via **Beehiiv**
- Plus cookie-based (non-OAuth) platforms via the **Postiz Chrome Extension** (e.g. Skool)

## Architecture

Postiz is NOT a single container. The stack contains:

| Component | Image | Role |
|---|---|---|
| `postiz` | `ghcr.io/gitroomhq/postiz-app` | Main app (NextJS frontend + NestJS backend) |
| `postiz-postgres` | `postgres:17-alpine` | App DB (via Prisma) |
| `postiz-redis` | `redis:7.2` | Cache + rate limits |
| `temporal` | `temporalio/auto-setup:1.31.0` | Workflow engine (for scheduled posts, retries) |
| `temporal-postgresql` | `postgres:16` | Temporal's own DB (separate from app DB) |
| `temporal-elasticsearch` | `elasticsearch:7.17.27` | Temporal's visibility / search |
| `temporal-admin-tools` | `temporalio/admin-tools` | tctl / temporal CLI |
| `temporal-ui` | `temporalio/ui:2.49.1` | Web UI for Temporal (port 8080) |
| `spotlight` (optional) | `ghcr.io/getsentry/spotlight` | Dev-only Sentry-like error viewer |

Minimum tested resources: 2 vCPU / 2 GB RAM VM (per upstream). ES alone has a 256MB Xms/Xmx limit in the default compose — be aware ES is the memory-heaviest component.

## ⚠️ v2.11.2 → v2.12.0 requires a manual Temporal migration

If you're upgrading an existing instance across this boundary, follow:
<https://docs.postiz.com/installation/migration>

Fresh installs on v2.12.0+ are fine.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose via `postiz-docker-compose` repo | <https://github.com/gitroomhq/postiz-docker-compose> | ✅ Recommended | Standard self-host. |
| Docker Compose (inline from docs) | <https://docs.postiz.com/installation/docker-compose> | ✅ | Same content; customize freely. |
| Docker run (single container) | <https://docs.postiz.com/installation/docker> | ⚠️ App only — you still need external Postgres + Redis + Temporal | Advanced. |
| Kubernetes / Helm | <https://docs.postiz.com/installation/kubernetes-helm> | ✅ | Clusters. |
| Dev / devcontainer | <https://docs.postiz.com/installation/devcontainer> | ✅ | Contributors. |
| Hosted (`postiz.com`) | Paid | ✅ managed | Don't want to maintain Temporal + ES. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `kubernetes` | Drives section. |
| dns | "Public URL?" | Free-text, e.g. `https://postiz.example.com` | Sets `MAIN_URL`, `FRONTEND_URL`, `NEXT_PUBLIC_BACKEND_URL`. These MUST agree. |
| ports | "Frontend port?" | Default `4007` | Container internally uses `5000`; compose maps `4007:5000`. |
| auth | "JWT secret?" | Random string, 32+ chars | `JWT_SECRET` — unique per install. |
| auth | "Disable self-signup?" | Boolean | `DISABLE_REGISTRATION=true` locks out new signups after admin account is created. |
| storage | "Media storage: local / Cloudflare R2?" | `AskUserQuestion`: `local` / `cloudflare-r2` | Uploaded post media goes to either `/uploads` volume or an R2 bucket. |
| social | "Which social platforms?" | Multi-select | For each, obtain OAuth client ID + secret from the platform's dev portal. |
| ai | "OpenAI API key?" | Free-text (sensitive) | Required for AI features (post generation). Optional if you skip AI. |
| oauth | "External OAuth (Authentik / other)?" | Boolean + fields | Optional SSO. Set `POSTIZ_GENERIC_OAUTH=true` and friends. |
| payments | "Stripe for billing (self-host monetization)?" | Boolean | Optional. Most self-hosters skip. |

## Install — Docker Compose

Based on upstream `docker-compose.yaml` (<https://github.com/gitroomhq/postiz-app/blob/main/docker-compose.yaml>). Minimum viable version:

```yaml
# compose.yaml
services:
  postiz:
    image: ghcr.io/gitroomhq/postiz-app:v2.21.7       # pin a version in prod
    container_name: postiz
    restart: always
    environment:
      MAIN_URL: "https://postiz.example.com"
      FRONTEND_URL: "https://postiz.example.com"
      NEXT_PUBLIC_BACKEND_URL: "https://postiz.example.com/api"
      JWT_SECRET: "replace-with-32-plus-random-chars"
      DATABASE_URL: "postgresql://postiz-user:postiz-password@postiz-postgres:5432/postiz-db-local"
      REDIS_URL: "redis://postiz-redis:6379"
      BACKEND_INTERNAL_URL: "http://localhost:3000"
      TEMPORAL_ADDRESS: "temporal:7233"
      IS_GENERAL: "true"
      DISABLE_REGISTRATION: "false"
      RUN_CRON: "true"
      STORAGE_PROVIDER: "local"
      UPLOAD_DIRECTORY: "/uploads"
      NEXT_PUBLIC_UPLOAD_DIRECTORY: "/uploads"
      # Add platform OAuth creds (empty = disabled):
      X_API_KEY: ""
      X_API_SECRET: ""
      # ... etc. See full env reference below.
    volumes:
      - postiz-config:/config/
      - postiz-uploads:/uploads/
    ports:
      - "4007:5000"
    networks: [postiz-network, temporal-network]
    depends_on:
      postiz-postgres:
        condition: service_healthy
      postiz-redis:
        condition: service_healthy

  postiz-postgres:
    image: postgres:17-alpine
    restart: always
    environment:
      POSTGRES_USER: postiz-user
      POSTGRES_PASSWORD: postiz-password
      POSTGRES_DB: postiz-db-local
    volumes:
      - postgres-volume:/var/lib/postgresql/data
    networks: [postiz-network]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postiz-user -d postiz-db-local"]
      interval: 10s
      timeout: 3s
      retries: 3

  postiz-redis:
    image: redis:7.2
    restart: always
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    volumes:
      - postiz-redis-data:/data
    networks: [postiz-network]

  # --- Temporal stack ---
  temporal-postgresql:
    image: postgres:16
    environment: { POSTGRES_USER: temporal, POSTGRES_PASSWORD: temporal }
    networks: [temporal-network]
    volumes: [/var/lib/postgresql/data]

  temporal-elasticsearch:
    image: elasticsearch:7.17.27
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms256m -Xmx256m
      - cluster.routing.allocation.disk.threshold_enabled=true
      - cluster.routing.allocation.disk.watermark.low=512mb
      - cluster.routing.allocation.disk.watermark.high=256mb
      - cluster.routing.allocation.disk.watermark.flood_stage=128mb
    networks: [temporal-network]
    volumes: [/var/lib/elasticsearch/data]

  temporal:
    image: temporalio/auto-setup:1.31.0
    ports: ["7233:7233"]
    depends_on: [temporal-postgresql, temporal-elasticsearch]
    environment:
      - DB=postgres12
      - DB_PORT=5432
      - POSTGRES_USER=temporal
      - POSTGRES_PWD=temporal
      - POSTGRES_SEEDS=temporal-postgresql
      - DYNAMIC_CONFIG_FILE_PATH=config/dynamicconfig/development-sql.yaml
      - ENABLE_ES=true
      - ES_SEEDS=temporal-elasticsearch
      - ES_VERSION=v7
      - TEMPORAL_NAMESPACE=default
    volumes:
      - ./dynamicconfig:/etc/temporal/config/dynamicconfig
    networks: [temporal-network]

  temporal-ui:
    image: temporalio/ui:2.49.1
    environment:
      - TEMPORAL_ADDRESS=temporal:7233
      - TEMPORAL_CORS_ORIGINS=http://127.0.0.1:3000
    ports: ["8080:8080"]
    networks: [temporal-network]

volumes:
  postgres-volume:
  postiz-redis-data:
  postiz-config:
  postiz-uploads:

networks:
  postiz-network:
  temporal-network:
    driver: bridge
```

You'll also need a `dynamicconfig/development-sql.yaml` — pull from <https://github.com/gitroomhq/postiz-app/tree/main/dynamicconfig>.

Bring up:

```bash
git clone https://github.com/gitroomhq/postiz-docker-compose
cd postiz-docker-compose
# Edit docker-compose.yml / .env to taste (fill in OAuth creds)
docker compose up -d
docker compose logs -f postiz
# → http://localhost:4007
```

## Obtaining OAuth credentials per platform

Postiz can't magic away the platform-specific OAuth onboarding. For each network you want:

| Platform | Developer portal |
|---|---|
| X (Twitter) | <https://developer.twitter.com> |
| LinkedIn | <https://www.linkedin.com/developers/> |
| Reddit | <https://www.reddit.com/prefs/apps> |
| GitHub | <https://github.com/settings/developers> |
| Instagram + Facebook | <https://developers.facebook.com> |
| Threads | <https://developers.facebook.com> (Threads API subset) |
| YouTube | Google Cloud Console — YouTube Data API v3 |
| TikTok | <https://developers.tiktok.com> |
| Pinterest | <https://developers.pinterest.com> |
| Dribbble | <https://dribbble.com/account/applications/new> |
| Discord | <https://discord.com/developers/applications> |
| Slack | <https://api.slack.com/apps> |
| Mastodon | Per-instance: `/settings/applications` on your instance. |
| Bluesky | App password in Bluesky settings (not OAuth). |

Each platform requires setting the **redirect URL** to `<MAIN_URL>/api/integrations/oauth/<platform>` (or similar — consult per-platform docs in <https://docs.postiz.com>). Mistakes in the redirect URL are the #1 cause of "signup works but connect fails" issues.

## Short-link providers (optional)

For link tracking on posts, Postiz can route URLs through: Dub, short.io, Kutt, LinkDrip. Configure in env vars (`DUB_TOKEN`, `SHORT_IO_SECRET_KEY`, etc.). Leave blank to skip.

## Reverse proxy

Postiz exposes port 4007. Terminate TLS at Caddy / Traefik / nginx:

```caddy
postiz.example.com {
    reverse_proxy postiz:5000
}
```

Note container internal port is `5000`; compose maps 4007→5000 by default.

## Data layout

| Path | Content |
|---|---|
| `postiz-config` volume → `/config/` | App config / generated secrets |
| `postiz-uploads` volume → `/uploads/` | User-uploaded post media |
| `postgres-volume` → `/var/lib/postgresql/data` | Postiz app DB (users, posts, schedules, OAuth tokens) |
| `postiz-redis-data` → `/data` | Redis persistence |
| Temporal data (postgres + ES volumes) | Workflow state |

**Backup** order of importance:

1. **postgres-volume** (Postiz DB) — contains users, posts, OAuth tokens. Most important.
2. **postiz-uploads** — your uploaded media.
3. Temporal's databases — workflow state. Re-creatable but in-flight scheduled posts will be lost.

Use `pg_dump` for Postgres, tar for volumes.

## Upgrade procedure

```bash
# READ migration docs if crossing v2.11.2 → v2.12.0:
# https://docs.postiz.com/installation/migration

docker compose pull
docker compose up -d
docker compose logs -f postiz
```

Prisma auto-migrates on startup. Release notes: <https://github.com/gitroomhq/postiz-app/releases>.

## Gotchas

- **Stack is multi-service + stateful.** ≥6 containers, 3 databases (Postiz PG + Temporal PG + ES). Not a "docker run and done" app. Budget at least 2 GB RAM.
- **`MAIN_URL`, `FRONTEND_URL`, `NEXT_PUBLIC_BACKEND_URL` must agree** in terms of scheme + host. If you reverse-proxy https → http, `NEXT_PUBLIC_BACKEND_URL` must still be `https://…`. Mismatch = browser CORS / SSL errors.
- **OAuth redirect URLs are the #1 footgun.** Each social platform's developer-console needs an EXACT redirect URI match. Typos, trailing slashes, http-vs-https all cause failed connections. Debug via the browser's devtools network tab.
- **Twitter/X API costs money now.** Free tier is severely limited (50 posts/day per user as of 2026). Basic paid tier $100/month. Consider this before promising users Twitter scheduling.
- **ElasticSearch is the memory hog.** Default 256MB Xmx works for small instances. Temporal's ES usage scales with workflow volume. On a 2 GB VM, ES + both Postgres + Postiz + Redis is tight.
- **Temporal is essentially a black box to most users.** If scheduled posts stop firing, check the Temporal UI at port 8080. Workflow errors often point to underlying OAuth expiry or platform rate limits.
- **Postgres 17 (app) vs Postgres 16 (Temporal).** Two different major versions in the same stack. Don't try to consolidate — Temporal's auto-setup image is pinned to older PG.
- **`JWT_SECRET` rotation invalidates all sessions.** If you change it, every user must re-log-in.
- **Chrome extension is for cookie-based platforms only.** OAuth platforms (X, LinkedIn, etc.) don't need it. Skool / similar closed platforms that require browser cookies DO need it — means the extension runs in YOUR browser and syncs session cookies to Postiz.
- **Local storage vs R2 vs S3.** Default is local (`/uploads` volume). For multi-replica deploys (Kubernetes), switch to R2 or S3-compatible; local storage won't be shared across replicas.
- **`temporal` container takes a while to be "ready."** Temporal auto-setup runs migrations on first boot — can be 30-60 seconds before the Postiz app finds it alive. Retries in the Postiz container should handle this; otherwise check `depends_on: condition: service_healthy`.
- **AGPL-3.0 means commercial SaaS resale has copyleft obligations.** Hosting Postiz as a paid service for 3rd parties requires you to offer the source (including modifications) to users. Most self-hosters are fine; SaaS operators need to read the license.
- **No built-in email sending.** Postiz uses Resend for transactional email (invites, password resets). You'll need a Resend API key OR another SMTP relay — check current env var docs.
- **`IS_GENERAL=true`** vs false toggles a hosted-vs-self-hosted feature flag. Always `true` for self-hosters.
- **`RUN_CRON=true`** enables the internal scheduler worker. Must be set in the main `postiz` container for scheduling to work at all. In HA setups you'd split cron-worker from API.
- **Analytics features depend on platform APIs giving you data.** Some platforms (TikTok, Threads) have limited analytics APIs; Postiz displays what platforms return, which is sometimes thin.
- **Upgrading across major Temporal versions** (1.28.x → 1.29.x, etc.) may require workflow migrations. Read Temporal docs + Postiz migration doc before changing that image tag.
- **Backup-and-restore isn't a dump of Redis.** Redis holds ephemeral session state; after restore, users log in again. Postgres is the thing that matters.
- **`DISABLE_REGISTRATION=true` after creating the first user** is a security best-practice for single-user / small-team instances.

## Links

- Upstream repo: <https://github.com/gitroomhq/postiz-app>
- Docker Compose repo: <https://github.com/gitroomhq/postiz-docker-compose>
- Docs: <https://docs.postiz.com>
- Quickstart: <https://docs.postiz.com/quickstart>
- Docker Compose install: <https://docs.postiz.com/installation/docker-compose>
- Kubernetes install: <https://docs.postiz.com/installation/kubernetes-helm>
- Env var reference: <https://docs.postiz.com/configuration/reference>
- Migration (v2.11.2 → v2.12.0+): <https://docs.postiz.com/installation/migration>
- Public API: <https://docs.postiz.com/public-api>
- NodeJS SDK: <https://www.npmjs.com/package/@postiz/node>
- N8N node: <https://www.npmjs.com/package/n8n-nodes-postiz>
- Make.com: <https://apps.make.com/postiz>
- Releases: <https://github.com/gitroomhq/postiz-app/releases>
- Hosted service: <https://postiz.com>
- Discord (devs): <https://discord.postiz.com>
