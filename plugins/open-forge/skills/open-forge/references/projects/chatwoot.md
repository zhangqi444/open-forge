---
name: chatwoot-project
description: Chatwoot recipe for open-forge. MIT-licensed open-source alternative to Intercom / Zendesk / Salesforce Service Cloud — unified inbox for customer support across live-chat website widget, email, Facebook, Instagram, Twitter, WhatsApp, Telegram, Line, SMS, API channel. Conversations, agents, teams, labels, canned responses, help-center portal, Slack/Shopify/Dialogflow integrations, CSAT reports, Captain AI agent (built-in). Tech: Ruby on Rails + Sidekiq + PostgreSQL (pgvector) + Redis. Covers the official Docker Compose production stack, env-var setup (REDIS_PASSWORD, SECRET_KEY_BASE, POSTGRES_PASSWORD, FRONTEND_URL), reverse proxy + SSL setup, Heroku / DigitalOcean 1-click alternatives, and upgrade procedure with DB migrations.
---

# Chatwoot

MIT-licensed customer support platform. Upstream: <https://github.com/chatwoot/chatwoot>. Docs: <https://chatwoot.com/help-center> + <https://www.chatwoot.com/docs>.

An open-source alternative to Intercom / Zendesk for omnichannel customer support. Agents work in one unified inbox that aggregates conversations from every channel your customers use: website live chat, email, Facebook, Instagram, Twitter (X), WhatsApp, Telegram, Line, SMS, Slack, plus a generic API channel for custom integrations.

## Features

- **Omnichannel inbox** — website live chat (embed widget on any site), email (IMAP/SMTP/OAuth), Facebook, Instagram DMs, WhatsApp (Cloud API / Twilio), Twitter (X), Telegram, Line, SMS (Twilio/Bandwidth/others), API channel
- **Agents + teams** — assign conversations, teams (Sales, Support, Billing), auto-assignment based on capacity
- **Help Center portal** — multi-lingual knowledge base hosted on the same instance, branded per inbox
- **Captain (AI agent)** — built-in GPT-powered agent (uses OpenAI API) that answers common questions automatically
- **Labels + views + filters + saved segments**
- **Canned responses** (team-wide template library)
- **Private notes + @mentions** (internal collaboration)
- **Integrations**: Slack (2-way mirror), Shopify (order lookup), Dialogflow (bot), Linear (ticket creation), Google Translate (message translation), Dashboard apps (embed any web app as a tab)
- **Automation rules**: conditional routing, auto-replies, business hours
- **Reports**: CSAT, conversation volume, agent productivity, per-team breakdowns
- **Public API + Webhooks** — for custom workflows

## Architecture

Ruby on Rails web app + Sidekiq worker, backed by PostgreSQL (**with pgvector** — for Captain AI) and Redis.

| Component | Image | Role |
|---|---|---|
| `rails` | `chatwoot/chatwoot` | Web + API |
| `sidekiq` | `chatwoot/chatwoot` (same image, different entrypoint) | Background jobs |
| `postgres` | `pgvector/pgvector:pg16` | App DB + vector embeddings for Captain |
| `redis` | `redis:alpine` | Cache + Sidekiq queue |

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (production) | <https://github.com/chatwoot/chatwoot/blob/develop/docker-compose.production.yaml> | ✅ Recommended | Most self-hosters. |
| Docker Compose (development) | <https://github.com/chatwoot/chatwoot/blob/develop/docker-compose.yaml> | ✅ | Contributors. Don't use for prod. |
| Kubernetes (Helm) | <https://artifacthub.io/packages/helm/chatwoot/chatwoot> | ✅ | Clusters. |
| Heroku 1-click deploy | <https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master> | ✅ | Quick managed-ish install. |
| DigitalOcean 1-click (K8s) | <https://marketplace.digitalocean.com/apps/chatwoot> | ✅ | DO users. |
| Bare-metal (from source) | <https://www.chatwoot.com/docs/self-hosted/deployment/linux-vm> | ✅ | Legacy-style VM installs. |
| Hosted Chatwoot Cloud | <https://www.chatwoot.com> | ✅ paid | Don't self-host. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `kubernetes-helm` / `heroku` / `digitalocean-1click` / `linux-vm` | Drives section. |
| dns | "Public domain?" | Free-text, e.g. `support.example.com` | Sets `FRONTEND_URL`. Must be accessible to your customers. |
| ports | "Rails port?" | Default `3000` | Container internal; map behind reverse proxy. |
| secret | "`SECRET_KEY_BASE`?" | Random 64+ chars | Required. Generate: `openssl rand -hex 64`. |
| db | "Postgres password?" | Free-text (sensitive) | Required. |
| db | "Redis password?" | Free-text (sensitive) | Required (production compose wraps Redis with `--requirepass`). |
| email | "SMTP config for outgoing email?" | Multi-field | Required for password resets, agent invites, customer email notifications. |
| email | "`MAILER_SENDER_EMAIL` + `MAILER_INBOUND_EMAIL_DOMAIN`?" | Email addresses | The latter is the domain customers can reply-to for email channel. |
| storage | "File storage: local / S3 / GCS / Azure?" | `AskUserQuestion` | Uploaded attachments. S3 recommended for multi-replica. |
| ai | "OpenAI API key (for Captain)?" | Free-text (sensitive) | Optional — enables the AI agent. |
| captcha | "Google reCAPTCHA keys?" | Optional | Abuse protection on signup / password-reset. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `caddy` / `nginx` / `traefik` | Required for HTTPS. |

## Install — Docker Compose (production)

Based on upstream `docker-compose.production.yaml` (<https://github.com/chatwoot/chatwoot/blob/develop/docker-compose.production.yaml>).

```bash
# 1. Clone the repo OR download only what you need
mkdir chatwoot && cd chatwoot
curl -fsSLO https://raw.githubusercontent.com/chatwoot/chatwoot/develop/docker-compose.production.yaml
curl -fsSLO https://raw.githubusercontent.com/chatwoot/chatwoot/develop/.env.example
mv .env.example .env

# 2. Edit .env — generate SECRET_KEY_BASE, set passwords, FRONTEND_URL, SMTP creds
$EDITOR .env

# 3. Initialize the database
docker compose --file docker-compose.production.yaml run --rm rails bundle exec rails db:chatwoot_prepare

# 4. Start the stack
docker compose --file docker-compose.production.yaml up -d

# 5. Watch logs
docker compose --file docker-compose.production.yaml logs -f
```

Open `https://support.example.com/` (behind your reverse proxy) → set up the admin account.

### Key env vars (from `.env.example`)

```bash
# Required
SECRET_KEY_BASE=<openssl rand -hex 64>
FRONTEND_URL=https://support.example.com
DEFAULT_LOCALE=en
FORCE_SSL=true
INSTALLATION_ENV=docker

# Postgres
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=<strong-random>
POSTGRES_DATABASE=chatwoot
POSTGRES_PORT=5432

# Redis
REDIS_URL=redis://:<password>@redis:6379
REDIS_PASSWORD=<strong-random>

# Email (outgoing)
MAILER_SENDER_EMAIL=Chatwoot <support@example.com>
SMTP_DOMAIN=example.com
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=<smtp-user>
SMTP_PASSWORD=<smtp-pass>
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer
MAILER_INBOUND_EMAIL_DOMAIN=support.example.com

# Storage (S3 example)
ACTIVE_STORAGE_SERVICE=s3_compatible
STORAGE_BUCKET_NAME=chatwoot-uploads
STORAGE_ACCESS_KEY_ID=<key>
STORAGE_SECRET_ACCESS_KEY=<secret>
STORAGE_REGION=us-east-1
STORAGE_ENDPOINT=https://s3.us-east-1.amazonaws.com

# Captain (AI agent) — optional
CAPTAIN_OPEN_AI_API_KEY=sk-...
CAPTAIN_OPEN_AI_MODEL=gpt-4o-mini
```

Full env reference: <https://www.chatwoot.com/docs/self-hosted/configuration/environment-variables>.

### Production compose (from upstream)

```yaml
# docker-compose.production.yaml — source: upstream
services:
  base: &base
    image: chatwoot/chatwoot:latest           # pin a version in prod
    env_file: .env
    volumes:
      - storage_data:/app/storage

  rails:
    <<: *base
    depends_on: [postgres, redis]
    ports:
      - "127.0.0.1:3000:3000"                 # localhost only — reverse-proxy in front
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
    entrypoint: docker/entrypoints/rails.sh
    command: ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
    restart: always

  sidekiq:
    <<: *base
    depends_on: [postgres, redis]
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
    command: ["bundle", "exec", "sidekiq", "-C", "config/sidekiq.yml"]
    restart: always

  postgres:
    image: pgvector/pgvector:pg16
    restart: always
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=chatwoot
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=

  redis:
    image: redis:alpine
    restart: always
    command: ["sh", "-c", "redis-server --requirepass \"$REDIS_PASSWORD\""]
    env_file: .env
    volumes:
      - redis_data:/data
    ports:
      - "127.0.0.1:6379:6379"

volumes:
  storage_data:
  postgres_data:
  redis_data:
```

Note all ports bind `127.0.0.1` — expose only the reverse proxy.

## Reverse proxy (Caddy example)

```caddy
support.example.com {
    reverse_proxy 127.0.0.1:3000
}
```

For WebSocket (ActionCable for real-time conversation updates), no special config needed with Caddy; nginx users need `proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade";` on the `/cable` location.

## Email — inbound (customers → Chatwoot)

Chatwoot can ingest emails via:

1. **SMTP forwarding** — route `*@<MAILER_INBOUND_EMAIL_DOMAIN>` to Chatwoot's inbound SMTP endpoint (requires a separate relay like postfix + a custom script OR SendGrid inbound parse).
2. **IMAP** — Chatwoot polls a mailbox on an existing IMAP server and imports new emails per-inbox.
3. **Microsoft 365 / Google OAuth** — configure in the inbox settings UI.

Reference: <https://www.chatwoot.com/docs/self-hosted/configuration/inbound-emails>.

## Helm chart (Kubernetes)

```bash
helm repo add chatwoot https://chatwoot.github.io/charts
helm install chatwoot chatwoot/chatwoot \
  --set env.FRONTEND_URL=https://support.example.com \
  --set env.SECRET_KEY_BASE=$(openssl rand -hex 64) \
  --set postgresql.auth.password=... \
  --set redis.auth.password=...
```

See <https://github.com/chatwoot/charts> for values reference.

## Data layout

| Path / volume | Content |
|---|---|
| `postgres_data` → `/var/lib/postgresql/data` | App DB — conversations, messages, users, settings |
| `storage_data` → `/app/storage` | Uploaded attachments (if `ACTIVE_STORAGE_SERVICE=local`) |
| `redis_data` → `/data` | Cache + Sidekiq queue. Rebuildable. |
| S3 bucket (if configured) | Attachments for production deploys |

**Backup priority:**

1. **Postgres** — everything. Use `pg_dump -Fc` regularly.
2. **Attachments** — either `storage_data` volume OR S3 bucket versioning.
3. `.env` — has all the secrets; store in a secret manager.

## Upgrade procedure

Chatwoot does DB migrations on startup when `INSTALLATION_ENV=docker`. Standard flow:

```bash
# 1. Back up Postgres + storage FIRST
docker compose --file docker-compose.production.yaml exec postgres \
  pg_dump -U postgres chatwoot > backup-$(date +%F).sql

# 2. Check release notes for breaking changes
# https://github.com/chatwoot/chatwoot/releases

# 3. Pull new image
docker compose --file docker-compose.production.yaml pull

# 4. Run migrations (safer than relying on entrypoint)
docker compose --file docker-compose.production.yaml run --rm rails \
  bundle exec rake db:migrate

# 5. Restart
docker compose --file docker-compose.production.yaml up -d

# 6. Watch logs
docker compose --file docker-compose.production.yaml logs -f rails sidekiq
```

Major-version upgrades (v3 → v4) have in the past required dedicated migration steps — ALWAYS read the release notes first.

## Gotchas

- **`INSTALLATION_ENV=docker` is mandatory.** Without it the app doesn't know it's containerized and certain default configs break.
- **`SECRET_KEY_BASE` must be set and stable.** Rotating it invalidates all sessions, password reset tokens, and encrypted columns (bad). Generate once, keep in a secret manager, never change unless compromised.
- **`FRONTEND_URL` is what the web widget embeds.** If you change it, all existing embedded chat widgets need to be re-deployed with the new URL. Pick your final public hostname BEFORE going live.
- **`FORCE_SSL=true` + no HTTPS reverse proxy = infinite redirect.** Chatwoot redirects http→https; if your proxy doesn't actually terminate TLS and forward the right `X-Forwarded-Proto` header, loops occur.
- **`REDIS_PASSWORD` must be URL-encoded in `REDIS_URL`.** Special chars in the password (`@`, `/`, `:`, `#`) break the connection string. Prefer ascii-alphanum passwords or URL-encode them.
- **pgvector extension is required** (the `pgvector/pgvector:pg16` image handles this). Plain `postgres:16` will fail schema-migration if you have Captain enabled.
- **DB init must run before first start.** `rails db:chatwoot_prepare` creates schemas + seeds. If you skip it, the app crashes on first HTTP request.
- **Inbound email is thorny.** Options (IMAP / OAuth / SMTP forwarding) all require external mail server cooperation. Expect to spend more time on email routing than on Chatwoot itself.
- **Attachments storage**: default is local (container volume). For multi-replica / Kubernetes, ALWAYS use S3-compatible storage; otherwise attachments exist only on one replica.
- **WhatsApp requires Meta Business API.** Not plug-and-play — requires verified business + phone number + WABA. Twilio's WhatsApp API is a quicker path.
- **Facebook / Instagram channels** require a Meta developer app with Pages API + Instagram Basic Display approval. Meta's review process is slow.
- **Captain AI uses OpenAI API tokens** → costs money per conversation. Budget accordingly. Model defaults (`gpt-4o-mini`) are cheap but not free.
- **Sidekiq queue backlog** happens when background jobs pile up (bulk operations, mass email). Monitor via the Sidekiq web UI at `/sidekiq` (admin-only).
- **Default installation has NO rate limit on signup.** For public-internet-facing deploys, enable reCAPTCHA (`RECAPTCHA_SITE_KEY` + `RECAPTCHA_SECRET_KEY`) OR disable public signup post-install via `ENABLE_ACCOUNT_SIGNUP=false`.
- **Multi-account mode.** Chatwoot supports multiple isolated "accounts" (tenants) per install. Default is `ENABLE_ACCOUNT_SIGNUP=true` → anyone who visits can create a new account. For single-tenant internal deploys, set to `false` immediately after creating your account.
- **Session cookie domain** matters behind reverse proxies. If cookies don't persist, check `SESSION_COOKIE_DOMAIN` env var.
- **Upgrading from v2 → v3** had a known breakage with encrypted DB columns; running `bundle exec rake db:migrate` fixes it. If you skipped migrations, you'll see decryption errors. Check release notes for v2-era upgrades.
- **Log volumes can grow.** Rails + Sidekiq write verbose logs in production if `RAILS_LOG_LEVEL=debug`. Default is `info`; leave it.
- **Action Cable (WebSocket) behind nginx** requires explicit WebSocket upgrade headers. Without them, agents see stale conversations (no realtime updates).
- **Heroku 1-click deploy** works but is expensive at scale (>$100/mo for a reasonable tier with workers + addons). Self-host on a VPS is ~10x cheaper for equivalent resources.

## Links

- Upstream repo: <https://github.com/chatwoot/chatwoot>
- Docs (self-host): <https://www.chatwoot.com/docs/self-hosted>
- Environment variables: <https://www.chatwoot.com/docs/self-hosted/configuration/environment-variables>
- Production Docker Compose: <https://github.com/chatwoot/chatwoot/blob/develop/docker-compose.production.yaml>
- Linux VM install: <https://www.chatwoot.com/docs/self-hosted/deployment/linux-vm>
- Helm chart: <https://artifacthub.io/packages/helm/chatwoot/chatwoot>
- Helm chart repo: <https://github.com/chatwoot/charts>
- Inbound emails: <https://www.chatwoot.com/docs/self-hosted/configuration/inbound-emails>
- Mobile SDKs: <https://github.com/chatwoot/chatwoot/tree/develop/app/javascript/widget>
- Heroku 1-click: <https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master>
- DigitalOcean 1-click: <https://marketplace.digitalocean.com/apps/chatwoot>
- Releases: <https://github.com/chatwoot/chatwoot/releases>
- Discord: <https://discord.gg/cJXdrwS>
- Hosted service: <https://www.chatwoot.com>
