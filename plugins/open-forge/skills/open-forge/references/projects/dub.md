---
name: dub-project
description: Dub recipe for open-forge. Covers self-hosting the open-source link attribution platform (short links, conversion tracking, affiliate programs). Self-hosting guide: https://dub.co/docs/self-hosting/guide
---

# Dub

Open-source link attribution platform for short links, conversion tracking, and affiliate programs. Built on Next.js + TypeScript + Prisma + MySQL + Upstash Redis + Tinybird. Upstream: <https://github.com/dubinc/dub>. Self-hosting guide: <https://dub.co/docs/self-hosting/guide>.

> **License note:** Dub is Open Core (AGPLv3 for the core; enterprise `/ee` directory under a commercial license). For self-hosting purposes the AGPLv3 core is FOSS-compliant.

Dub is a **complex multi-service application** with external service dependencies. The docker-compose file included in the repo (`apps/web/docker-compose.yml`) is **for local development only** — it provides a local MySQL (via PlanetScale HTTP proxy) and Mailhog for SMTP simulation. Production self-hosting requires provisioning the external services listed below.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Self-hosting guide (Docker + external services) | https://dub.co/docs/self-hosting/guide | ✅ | Production self-hosting. Requires external managed services. |
| Local development (Docker Compose) | https://dub.co/docs/local-development | ✅ | Dev/testing only. Not for production. |

## External service dependencies

Self-hosting Dub requires the following external services (as of upstream docs):

| Service | Purpose | Notes |
|---|---|---|
| MySQL / PlanetScale | Primary database | Local dev uses PlanetScale HTTP proxy sim |
| Upstash Redis | Caching and rate limiting | REST API mode required |
| Upstash QStash | Background job queues | REST API required |
| Tinybird | Click analytics pipeline | API key required |
| Resend | Transactional email | Or any SMTP provider |
| Vercel Domains API | Custom domain management | Only needed for multi-tenant custom domains |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | Options: self-hosting / local-dev | Drives which path |
| app | "App domain (e.g. links.example.com)?" | Free-text | All |
| app | "App short domain (e.g. short.example.com)?" | Free-text | All |
| app | "App display name?" | Free-text | e.g. Dub |
| secrets | NEXTAUTH_SECRET | node -e "console.log(require('crypto').randomBytes(32).toString('base64'))" | All |
| secrets | ENCRYPTION_KEY (AES-256) | Same generator | All |
| secrets | CRON_SECRET | Same generator | All |
| database | DATABASE_URL | mysql://user:pass@host:port/dbname | All |
| database | PLANETSCALE_DATABASE_URL | HTTP proxy URL | All |
| cache | UPSTASH_REDIS_REST_URL | From Upstash console | All |
| cache | UPSTASH_REDIS_REST_TOKEN | From Upstash console | All |
| queue | QSTASH_TOKEN + signing keys | From Upstash console | All |
| analytics | TINYBIRD_API_KEY | From Tinybird workspace | All |
| analytics | TINYBIRD_API_URL | Regional endpoint e.g. https://api.tinybird.co | All |
| email | RESEND_API_KEY | From Resend dashboard | All |
| domains (opt) | TEAM_ID_VERCEL + VERCEL_API_KEY | From Vercel account | Custom domains only |

## Software-layer concerns

### Key env vars (from apps/web/.env.example)

```
NEXT_PUBLIC_APP_NAME=Dub
NEXT_PUBLIC_APP_DOMAIN=<your-domain>
NEXT_PUBLIC_APP_SHORT_DOMAIN=<your-short-domain>

NEXTAUTH_SECRET=<generated>
NEXTAUTH_URL=https://<your-domain>
CRON_SECRET=<generated>
ENCRYPTION_KEY=<generated>

DATABASE_URL=mysql://user:pass@host/db
PLANETSCALE_DATABASE_URL=http://user:pass@host/db

UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
QSTASH_TOKEN=
QSTASH_CURRENT_SIGNING_KEY=
QSTASH_NEXT_SIGNING_KEY=

TINYBIRD_API_KEY=
TINYBIRD_API_URL=https://api.tinybird.co

RESEND_API_KEY=
RESEND_WEBHOOK_SECRET=
```

### Local dev Docker Compose (apps/web/docker-compose.yml — dev only)

```yaml
services:
  ps-mysql:           # MySQL 8.0 (simulates PlanetScale)
  planetscale-proxy:  # ghcr.io/mattrobenolt/ps-http-sim — HTTP-mode proxy
  mailhog:            # Email capture for dev (ports 1025 + 8025)
```

Start dev stack:

```bash
cd apps/web
docker compose up -d
cp .env.example .env
# Fill in .env with dev values
pnpm install
pnpm prisma:push       # push schema to local MySQL
pnpm dev               # start Next.js dev server
```

### Recommended package versions

| Package | Version |
|---|---|
| node | v23.11.0 |
| pnpm | 9.15.9 |

## Upgrade procedure

```bash
git pull origin main
pnpm install                # update deps
pnpm prisma:push            # apply any schema changes
pnpm build                  # rebuild
# redeploy / restart the app
```

Check the upstream changelog at https://github.com/dubinc/dub/releases for breaking changes before upgrading.

## Gotchas

- **External service dependencies are not optional.** Dub's architecture hard-requires Upstash Redis, Tinybird, and a PlanetScale-compatible MySQL endpoint. There is no "pure self-hosted, no external services" path documented upstream.
- **Docker Compose is dev-only.** The apps/web/docker-compose.yml is explicitly labelled "meant for local development only". It does not include the Next.js app itself — only backing services.
- **Open Core licensing.** The AGPLv3 core is FOSS. The /ee enterprise directory is under a commercial license. The core is sufficient for most self-hosting use cases.
- **Custom domains require Vercel API.** The multi-tenant custom domain feature depends on Vercel's Domains API. Only relevant for building a link-shortener product with per-user custom domains.
- **Node + pnpm versions matter.** Use exactly Node v23.11.0 and pnpm 9.15.9. Delete all node_modules, .next, and .turbo dirs if the build misbehaves.
- **NEXTAUTH_URL required for localhost.** Set NEXTAUTH_URL=http://localhost:<port> for local dev; in production it is inferred from the deployment URL.

## Upstream docs

- Self-hosting guide: https://dub.co/docs/self-hosting/guide
- Local development: https://dub.co/docs/local-development
- GitHub README: https://github.com/dubinc/dub
- Env vars reference: apps/web/.env.example in the repo
