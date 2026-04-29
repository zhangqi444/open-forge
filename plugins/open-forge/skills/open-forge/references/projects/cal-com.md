---
name: cal-com-project
description: Cal.com recipe for open-forge. AGPLv3 open-source scheduling infrastructure — Calendly alternative with event types, team calendars, video integrations (Daily / Zoom / Google Meet), routing forms, workflows, and API v2. Self-hosts via the upstream docker-compose (Next.js web + Postgres + Redis + separate API-v2 service). Covers the env-heavy setup (NEXTAUTH_SECRET, CALENDSO_ENCRYPTION_KEY, DATABASE_URL, DB integrations with Google/Microsoft calendar), the open-core/EE boundary (Teams/SAML/SSO), and the common upgrade pain (Prisma migrations, yarn → pnpm).
---

# Cal.com

AGPLv3 open-source scheduling platform. Upstream: <https://github.com/calcom/cal.com>. Docs: <https://cal.com/docs>. Self-hosting docs: <https://cal.com/docs/self-hosting/installation>.

Cal.com is a Next.js app. The monorepo contains:

- `apps/web/` — main Next.js app (port 3000)
- `apps/api/v2/` — standalone NestJS API v2 service (port configurable)
- Postgres (database) + Redis (queues, caching)
- Optional: organization features, SAML SSO (gated behind `.ee/` Enterprise Edition code)

## Open-core / EE boundary

**Core is AGPLv3 and free.** Some code lives under `apps/web/modules/ee/` and `packages/features/ee/` — that's Enterprise Edition, source-available but requires a commercial license to use in production. Examples:

- **Organizations / Teams Plus** (beyond 5 seats): EE
- **SAML SSO / SCIM**: EE
- **Workflows SMS**: EE (cost also comes from Twilio)
- **Billing / Stripe inside Cal's UI**: EE

Check the LICENSE file in any `/ee/` subfolder before using those features in production. Upstream's docs at <https://cal.com/docs/self-hosting/license-keys> cover paid license keys.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (upstream repo) | `docker-compose.yml` on `main` | ✅ | The open-forge-preferred shape. Builds from the repo's Dockerfile. |
| `calcom/docker` separate repo | <https://github.com/calcom/docker> | ✅ | An alternative compose repo; maintained but lags main repo slightly. |
| Vercel + managed Postgres | <https://cal.com/docs/self-hosting/installation#vercel> | ✅ | Their own prod deployment shape. Serverless; API-v2 needs a separate host. |
| Build from source (yarn/pnpm) | <https://cal.com/docs/self-hosting/installation#manual> | ✅ | Dev / contributors. |
| Railway / Render / Fly one-click | Templates in docs | ✅ | Quick cloud deploys. |
| DigitalOcean App Platform | <https://cal.com/docs/self-hosting/deployments/do> | ✅ | DO integrations. |
| Kubernetes (Helm, community) | <https://github.com/calcom/helm> | ⚠️ Community | Helm chart exists but drifts. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| dns | "Public domain?" | Free-text | `NEXT_PUBLIC_WEBAPP_URL` / `NEXTAUTH_URL`. |
| secrets | "`NEXTAUTH_SECRET` (32+ byte hex)?" | Auto-generated via `openssl rand -hex 32` | NextAuth session signing. Change only during full user re-auth window. |
| secrets | "`CALENDSO_ENCRYPTION_KEY` (32-byte hex)?" | Auto-generated via `openssl rand -hex 32` | Encrypts calendar OAuth tokens at rest. **Losing this bricks every integration** — users must reconnect Google/Microsoft calendars. |
| db | "Postgres creds?" | `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` / `DATABASE_HOST` | Built-in Postgres in compose, or external. |
| redis | "Redis URL?" | `REDIS_URL=redis://...` | Built-in Redis in compose. |
| email | "SMTP for invitation emails / magic links?" | `EMAIL_SERVER_HOST` / `EMAIL_SERVER_PORT` / `EMAIL_SERVER_USER` / `EMAIL_SERVER_PASSWORD` / `EMAIL_FROM` | Required. Without SMTP, invitation flows and password resets silently break. |
| oauth | "Google / Microsoft calendar OAuth credentials?" | Client IDs + secrets per provider | Users connect their calendars to Cal; requires OAuth apps registered at Google/MS. Can be deferred. |
| api | "Enable API v2?" | Boolean | Separate `calcom-api` service on a different port. |
| license | "Enterprise Edition features?" | Boolean → `CALCOM_LICENSE_KEY` | Only if paying for EE features. |

## Install — Docker Compose (upstream repo)

```bash
git clone https://github.com/calcom/cal.com.git
cd cal.com

# 1. Populate .env
cp .env.example .env
# Edit .env and set:
#   NEXTAUTH_SECRET=<openssl rand -hex 32>
#   CALENDSO_ENCRYPTION_KEY=<openssl rand -hex 32>
#   NEXT_PUBLIC_WEBAPP_URL=https://cal.example.com
#   NEXTAUTH_URL=https://cal.example.com
#   DATABASE_URL=postgresql://unicorn_user:magical_password@database:5432/calendso
#   POSTGRES_USER=unicorn_user
#   POSTGRES_PASSWORD=magical_password
#   POSTGRES_DB=calendso
#   DATABASE_HOST=database
#   REDIS_URL=redis://redis:6379
#   EMAIL_SERVER_HOST=... (SMTP)
#   EMAIL_FROM=notifications@example.com

# 2. Build + start (FIRST build takes 10-20 min — compiles full Next.js app)
docker compose build
docker compose up -d

# 3. Run DB migrations (one-shot; the main service does this on boot too)
docker compose exec calcom npx prisma migrate deploy

# 4. Create first admin user via signup at https://cal.example.com/signup
#    (or create via SQL / API)
```

### Key env vars (from `.env.example`)

| Var | Purpose |
|---|---|
| `NEXT_PUBLIC_WEBAPP_URL` | Public canonical URL. Must match browser URL exactly (protocol + host + port). |
| `NEXTAUTH_URL` | Same as above; used by NextAuth for callback URLs. |
| `NEXTAUTH_SECRET` | Session JWT signing key. |
| `CALENDSO_ENCRYPTION_KEY` | AES key for calendar OAuth tokens in DB. **Irrecoverable if lost.** |
| `DATABASE_URL` | Prisma connection string. |
| `REDIS_URL` | Redis for queues (Workflows, bookings notifications). |
| `EMAIL_SERVER_*` + `EMAIL_FROM` | SMTP for invite/reset emails. |
| `CALCOM_TELEMETRY_DISABLED` | `1` to opt out of anonymous telemetry. |
| `NEXT_PUBLIC_LICENSE_CONSENT` | `agree` required — upstream wants explicit consent acknowledging AGPL. |
| `CALCOM_LICENSE_KEY` | Paid EE license key; leave empty for free self-host. |
| `NEXT_PUBLIC_API_V2_URL` | Public URL of the API-v2 service. |
| `NEXT_PUBLIC_SINGLE_ORG_SLUG` | Single-tenant mode (one org, hides multi-org UI). |

## Reverse proxy (Caddy)

```caddy
cal.example.com {
    reverse_proxy 127.0.0.1:3000
}

api.cal.example.com {
    reverse_proxy 127.0.0.1:80    # API v2 service
}
```

## OAuth provider setup

### Google Calendar / Google Meet

1. <https://console.cloud.google.com> → new project.
2. OAuth consent screen → External, add `cal.example.com` + user emails in "Test users" (until verified).
3. Enable APIs: Calendar API, Google Meet API.
4. Credentials → OAuth Client ID → Web app. Authorized redirect URI: `https://cal.example.com/api/integrations/googlecalendar/callback` (and `/api/integrations/googlevideo/callback` for Meet).
5. Download the JSON and paste into the "Google Calendar App" on your Cal admin page at `https://cal.example.com/settings/admin/apps`.

### Microsoft 365 / Outlook Calendar

1. <https://portal.azure.com> → App registrations → New.
2. Redirect URI: `https://cal.example.com/api/integrations/office365calendar/callback`.
3. API permissions: `Calendars.ReadWrite`, `MailboxSettings.Read`, `User.Read` (delegated).
4. Paste client ID + secret into the Office365 app in Cal admin.

### Daily.co (video)

Create a Daily account → API key → set `DAILY_API_KEY` and `DAILY_SCALE_PLAN` env → Daily video auto-creates per-event rooms.

### Other integrations

Setup UI at `https://<your-cal>/settings/admin/apps`. Each provider requires its own OAuth app.

## Upgrade procedure

```bash
cd /path/to/cal.com
git fetch && git checkout v5.x.x       # pin to a release tag; avoid `main`
docker compose build                   # can take 10–20 min on first build
docker compose up -d
docker compose exec calcom npx prisma migrate deploy
docker compose logs -f calcom
```

Cal.com upgrades almost always include Prisma migrations. Read the release notes at <https://github.com/calcom/cal.com/releases> first — occasionally a migration is irreversible or requires a data-fix step.

### Backup before upgrading

```bash
docker compose exec database pg_dump -U unicorn_user calendso > calendso-$(date +%F).sql
```

Keep at least 2 backups so you can roll back if a migration fails.

## Data model

- `Users` — account records + hashed passwords (for email/password signup) + OAuth IDs.
- `EventTypes` — per-user event definitions (duration, availability rules).
- `Bookings` — individual scheduled appointments, with attendee info.
- `Credentials` — **encrypted** OAuth tokens for Google/MS/etc (encrypted with `CALENDSO_ENCRYPTION_KEY`).
- `Workflows` — scheduled reminders / confirmations / workflows.
- `Teams`, `Memberships` — team scheduling.

Backing up is `pg_dump` + a note of what `CALENDSO_ENCRYPTION_KEY` was when the dump was taken.

## Gotchas

- **`CALENDSO_ENCRYPTION_KEY` loss = every integration broken.** All stored Google/MS calendar OAuth tokens become undecryptable. Users must reconnect every integration, which also requires their OAuth apps to still be valid. Treat this key like the master key of a password manager — put it in a secret store.
- **`NEXTAUTH_SECRET` rotation forces re-login.** Not destructive but annoying — every logged-in user gets bounced to `/auth/login`.
- **Build time.** First `docker compose build` takes 10–20 min and 4+ GB RAM; CI-style builds timeout. On small VPS, build elsewhere + push to a registry OR use upstream's prebuilt image (when available).
- **`CALCOM_TELEMETRY_DISABLED=1`** — default is to send telemetry. Set to 1 for fully-private deploys.
- **`NEXT_PUBLIC_LICENSE_CONSENT=agree`** — app boot fails without this explicit acknowledgment of AGPL terms.
- **Two URLs.** `NEXTAUTH_URL` and `NEXT_PUBLIC_WEBAPP_URL` must match. Mismatch causes redirect loops on login.
- **OAuth redirect URIs are exact.** Adding `/` or port mismatches → Google returns `redirect_uri_mismatch`. Copy-paste from Cal's admin panel.
- **Prisma migrations on upgrade.** Always run `npx prisma migrate deploy` after `docker compose up -d`. The main app runs it automatically but only on fresh boots; failed boots don't trigger migrations.
- **Time zones.** Server timezone should be `UTC` (the default in upstream Dockerfile). Cal.com handles per-user timezones in-app; server-local TZ causes subtle booking-time drift.
- **API v2 is separate.** Running `apps/web/` alone gives you the UI and webhooks-capable API v1; v2 is NestJS and lives in `apps/api/v2/` — needs its own container.
- **EE code in `/ee/` folders.** If you enable Organizations / SAML / Workflow SMS without a license, you're violating the commercial EE license. Check before enabling.
- **No SMTP = silent failures.** Invite links, magic-link login, cancellation emails all just disappear. Set up a real SMTP provider before testing flows.
- **Open-core reality check.** Cal.com's free-tier is generous for 1–5 users; teams beyond that hit EE features like advanced workflows + SSO. For free sustainable, target personal / small-team use.

## Links

- Upstream repo: <https://github.com/calcom/cal.com>
- Docs: <https://cal.com/docs>
- Self-hosting: <https://cal.com/docs/self-hosting/installation>
- Env var reference: <https://cal.com/docs/self-hosting/environment-variables>
- License keys: <https://cal.com/docs/self-hosting/license-keys>
- Docker compose repo: <https://github.com/calcom/docker>
- Helm chart (community): <https://github.com/calcom/helm>
- Releases: <https://github.com/calcom/cal.com/releases>
- Slack: <https://go.cal.com/slack>
