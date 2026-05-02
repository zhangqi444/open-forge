# Wapy.dev

**Smart subscription and recurring expense tracker**
Official site: https://github.com/meceware/wapy.dev

Wapy.dev tracks subscriptions and recurring payments with email/push/webhook notifications, multi-currency support, category management, payment history, and detailed analytics. Sign in with email, GitHub, Google, or generic OAuth (Keycloak, Authentik). Runs as a Next.js app with PostgreSQL and a cron sidecar.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker-compose | Three containers: app + Postgres + Alpine cron |
| VPS | docker-compose | Requires SMTP for email notifications |

## Inputs to Collect

### Phase: Pre-deployment (required)
- `SITE_URL` — public URL without trailing slash (e.g. `https://wapy.example.com`)
- `POSTGRES_PASSWORD` — PostgreSQL password
- `DATABASE_URL` — full Prisma connection string (update password)
- `AUTH_SECRET` — random secret for Better Auth (`openssl rand -base64 32`)

### Phase: Notifications (optional but recommended)
- `EMAIL_SERVER_HOST`, `EMAIL_SERVER_PORT`, `EMAIL_SERVER_USER`, `EMAIL_SERVER_PASSWORD` — SMTP config
- `EMAIL_FROM` — sender address
- `EMAIL_CONTACT_EMAIL` — contact form destination

### Phase: OAuth (optional)
- `GITHUB_ID` / `GITHUB_SECRET` — GitHub OAuth app credentials
- `GOOGLE_ID` / `GOOGLE_SECRET` — Google OAuth credentials
- `GENERIC_AUTH_*` — Generic OAuth (Keycloak, Authentik, etc.)

## Software-Layer Concerns

**Docker image:** `ghcr.io/meceware/wapy.dev:latest`

**Three-container setup:**
1. `db` — PostgreSQL 17 with `./db` bind-mount
2. `app` — Next.js app on port `3000`
3. `cron` — Alpine container running `wget` every 60s to hit `/api/cron/` (triggers payment reminders)

**Config:** `.env` file loaded via `env_file` in `docker-compose.yml`

**Key env vars:**
| Variable | Purpose |
|----------|---------|
| `SITE_URL` | Public URL — used in notification links and OAuth redirects |
| `AUTH_SECRET` | Better Auth signing secret |
| `DATABASE_URL` | Prisma PostgreSQL URL |
| `DISABLE_USER_REGISTRATION` | Set `true` after registering to lock signups |

**Push notifications:** Uses Web Push API — no third-party service needed; handled server-side.

**Helper script:** `./scripts/setup.sh` can auto-generate `POSTGRES_PASSWORD` and `AUTH_SECRET` if not set.

## Upgrade Procedure

1. Pull new image: `docker-compose pull app`
2. Recreate: `docker-compose up -d`
3. Prisma migrations run automatically on app startup
4. PostgreSQL data in `./db` persists across upgrades

## Gotchas

- **Lock registration after setup** — set `DISABLE_USER_REGISTRATION=true` after creating your account to prevent unauthorized signups
- **Cron sidecar required** — payment reminders won't fire without the Alpine cron container polling `/api/cron/`; don't skip it
- **`SITE_URL` must be exact** — OAuth callbacks and push notification links use this; trailing slash or wrong scheme breaks auth
- **Email optional but useful** — without SMTP config, notification reminders only work via browser push
- **License: MIT + Commons Clause** — free for personal self-hosting; commercial use/resale restricted

## References
- Upstream README: https://github.com/meceware/wapy.dev/blob/HEAD/README.md
- Docker Compose: https://github.com/meceware/wapy.dev/blob/HEAD/docker-compose.yml
- Environment variables: https://github.com/meceware/wapy.dev/wiki/Environment-Variables
