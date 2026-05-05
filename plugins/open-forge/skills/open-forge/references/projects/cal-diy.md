---
name: cal-diy-project
description: Cal.diy recipe for open-forge. Community-driven, 100% MIT-licensed open-source scheduling platform (fork of Cal.com). Next.js + PostgreSQL + Redis. Upstream: https://github.com/calcom/cal.diy
---

# Cal.diy

Community-driven, fully open-source scheduling platform — a 100% MIT-licensed fork of Cal.com with all enterprise/commercial code removed. Lets users create booking pages, manage availability, and accept appointments. Built with Next.js, tRPC, Prisma, and PostgreSQL. Designed for personal and small-team self-hosting. No license key or Cal.com account required. Upstream: https://github.com/calcom/cal.diy

> Upstream warning: Cal.diy is intended for personal, non-production use. Self-hosting requires knowledge of server administration, database management, and securing sensitive data.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS/bare-metal | Docker Compose (official) | Primary method; includes PostgreSQL + Redis |
| Any Linux VPS/bare-metal | Node.js (manual) | Requires Node 18+, PostgreSQL 13+, Yarn |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Public URL (e.g. https://cal.yourdomain.com) | NEXT_PUBLIC_WEBAPP_URL — baked into Next.js build |
| preflight | PostgreSQL credentials | Or use Compose-bundled postgres |
| secrets | NEXTAUTH_SECRET (32-char random) | `openssl rand -base64 32` |
| secrets | CALENDSO_ENCRYPTION_KEY (32-char random) | `openssl rand -base64 32` |
| email | SMTP host, port, user, password | For booking confirmation emails |
| email | From address | Outbound email identity |
| integrations | Calendar OAuth credentials (Google, Outlook) | Optional; per-integration setup |

## Software-layer concerns

### Docker Compose setup

```bash
git clone https://github.com/calcom/cal.diy.git
cd cal.diy
cp .env.example .env
# Edit .env with your values
docker compose up -d
```

### Critical .env variables

```bash
# App URL — baked into the build; must match public domain
NEXT_PUBLIC_WEBAPP_URL=https://cal.yourdomain.com

# Database
DATABASE_URL=postgresql://unicorn_user:magical_password@database:5432/calendso
POSTGRES_USER=unicorn_user
POSTGRES_PASSWORD=magical_password
POSTGRES_DB=calendso
DATABASE_HOST=database

# Auth / encryption — generate unique values before first run
NEXTAUTH_SECRET=<openssl rand -base64 32>
CALENDSO_ENCRYPTION_KEY=<openssl rand -base64 32>

# Email
EMAIL_FROM=noreply@yourdomain.com
EMAIL_SERVER_HOST=smtp.yourdomain.com
EMAIL_SERVER_PORT=465
EMAIL_SERVER_USER=user
EMAIL_SERVER_PASSWORD=password

# Optional
CALCOM_TELEMETRY_DISABLED=1
```

Full .env.example: https://github.com/calcom/cal.diy/blob/main/.env.example

### Services in Compose stack

| Container | Purpose |
|---|---|
| database | PostgreSQL (booking data, users, calendars) |
| redis | Session caching, job queue |
| calcom | Next.js web app (port 3000) |
| calcom-api | REST API v2 (port 80 by default, API_PORT env) |

### Port reference

- 3000 — Web UI (Next.js)
- 6379 — Redis (internal)
- 5432 — PostgreSQL (internal)
- 80 — API v2 (configurable via API_PORT)

### Reverse proxy (nginx example)

```nginx
server {
    server_name cal.yourdomain.com;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Data persistence

Docker volumes:
- database-data — PostgreSQL data
- redis-data — Redis data

Back up the PostgreSQL volume regularly.

## Upgrade procedure

```bash
cd cal.diy
git pull origin main
docker compose pull
docker compose up -d --build
```

The --build flag is required because NEXT_PUBLIC_WEBAPP_URL is embedded at build time.
Check for breaking changes: https://github.com/calcom/cal.diy/releases

## Gotchas

- NEXT_PUBLIC_WEBAPP_URL is baked into the build — this URL is embedded at Docker image build time, not runtime. Domain changes require a full image rebuild.
- Secrets must be set before first run — NEXTAUTH_SECRET and CALENDSO_ENCRYPTION_KEY must be set before the first docker compose up; changing them later invalidates existing sessions and encrypted data.
- No enterprise features — Teams, Organizations, SAML/SSO, Workflows, and Insights from Cal.com are not in Cal.diy.
- Calendar OAuth setup — integrating Google Calendar, Outlook, etc. requires creating OAuth apps in each provider's developer console and adding credentials to .env.
- PostgreSQL 13+ required — older versions are untested.
- Redis required — handles session and queue work; do not remove from Compose stack.
- Personal/non-production intent — upstream explicitly warns this is not hardened for commercial production use.
- Email required — booking confirmations require working SMTP configuration.

## Links

- Upstream repo: https://github.com/calcom/cal.diy
- Docker Hub: https://hub.docker.com/r/calcom/cal.diy
- .env.example: https://github.com/calcom/cal.diy/blob/main/.env.example
- Discussions: https://github.com/calcom/cal.diy/discussions
