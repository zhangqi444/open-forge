---
name: payload-project
description: Payload recipe for open-forge. MIT-licensed Next.js-native headless CMS + application framework. Installs directly into an existing Next.js `/app` folder; ships as an npm package, NOT a standalone server. Covers the `create-payload-app` scaffold, the self-host Docker deploy (your Next.js app + Postgres/MongoDB/SQLite), one-click deploys (Vercel + Neon, Cloudflare Workers + D1 + R2), and the open-core reality (core MIT, Payload Cloud managed service is the commercial offering — no feature paywalls in the open-source binary).
---

# Payload

MIT-licensed headless CMS + application framework for Next.js. Upstream: <https://github.com/payloadcms/payload>. Docs: <https://payloadcms.com/docs>.

**Payload is not a standalone server; it's an npm package.** You add it to a Next.js app's `/app` folder and Next.js serves both the admin UI and the collections REST/GraphQL API. Unlike Ghost / Strapi / Directus, there is no `payload start` daemon — `next dev` / `next start` is the entry point.

## Licensing

Everything on GitHub is MIT (including the admin UI, queries, access control, hooks, rich text editor). Payload Cloud is the commercial managed-hosting offering; it adds nothing to the self-host binary that you can't get via self-host. No per-seat pricing in the OSS path.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `create-payload-app` CLI | <https://payloadcms.com/docs/getting-started/installation> | ✅ Recommended | Scaffolds a new Next.js + Payload app from a template. |
| Add to existing Next.js app | `pnpm add payload @payloadcms/next @payloadcms/db-postgres` | ✅ | Integrate Payload into an app you already have. |
| Docker (BYO Dockerfile) | Community patterns; no official image | ⚠️ BYO | Production self-host pattern. Upstream doesn't publish an official Docker image because Payload is bundled INTO your app, not shipped standalone. |
| Vercel + Neon + Vercel Blob | One-click deploy button | ✅ | Serverless; free tier available. |
| Cloudflare Workers + D1 + R2 | One-click deploy button | ✅ | Edge-native; fully self-contained. |
| Netlify / Railway / Render | Docs have per-host guides | ✅ | Other PaaS deploys. |
| K8s (BYO) | No upstream Helm chart | ⚠️ BYO | Containerize your Next.js app + Postgres; use standard K8s patterns. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "New app or existing Next.js app?" | `AskUserQuestion` | Drives scaffold vs integration path. |
| template | "Starter template?" | `AskUserQuestion`: `blank` / `website` / `ecommerce` / `custom` | `create-payload-app -t <template>`. |
| db | "Database?" | `AskUserQuestion`: `Postgres (recommended)` / `MongoDB` / `SQLite` / `MySQL (beta)` | Picks the `@payloadcms/db-*` adapter. |
| deploy | "Deploy target?" | `AskUserQuestion`: `Self-host Docker` / `Vercel` / `Cloudflare Workers` / `Railway/Render/Fly` / `Other` | Drives hosting-specific config. |
| secrets | "`PAYLOAD_SECRET` (strong random)?" | Auto-generate via `openssl rand -hex 32` | JWT signing key + collection-data encryption. |
| db-conn | "Database connection string?" | Free-text | `DATABASE_URI` (or `POSTGRES_URL` / `MONGODB_URI` depending on adapter). |
| storage | "Media storage?" | `AskUserQuestion`: `Local filesystem` / `S3` / `Vercel Blob` / `Cloudflare R2` / `Azure Blob` / `Google Cloud Storage` | `@payloadcms/storage-*` plugins. |
| domain | "Public URL?" | Free-text | `NEXT_PUBLIC_SERVER_URL` / `PAYLOAD_PUBLIC_SERVER_URL`. |
| email | "SMTP / transactional email provider?" | Free-text | `nodemailer` config for `forgot-password`, email verification, etc. |

## Install — `create-payload-app` (new project)

```bash
# Node 20.9+ required (see https://payloadcms.com/docs/getting-started/installation)
pnpx create-payload-app@latest
# Interactive prompts:
#   Project name?  my-cms
#   Template?      website (recommended for newcomers) / blank / ecommerce / ...
#   DB adapter?    postgres / mongodb / sqlite
# → creates ./my-cms/ with Next.js + Payload + Tailwind (if website template)

cd my-cms
cp .env.example .env
# Edit .env:
#   DATABASE_URI=postgresql://user:pass@localhost:5432/mycms
#   PAYLOAD_SECRET=$(openssl rand -hex 32)
#   NEXT_PUBLIC_SERVER_URL=http://localhost:3000

pnpm install
pnpm dev
# → Admin UI at http://localhost:3000/admin
# → First visit prompts to create the initial admin user
```

Templates: <https://github.com/payloadcms/payload/tree/main/templates>.

## Install — Add to existing Next.js app

```bash
pnpm add payload @payloadcms/next @payloadcms/db-postgres @payloadcms/richtext-lexical
```

Then follow the integration guide: <https://payloadcms.com/docs/beta/custom-routes>. Core work:

1. Create `payload.config.ts` at the app root.
2. Add `payloadPlugin()` to `next.config.mjs`.
3. Add `/(payload)/admin/[[...segments]]/page.tsx` and related route-group files to `/app/`.

## Deploy — Self-host Docker

Payload doesn't ship an official image, but the pattern is a standard Next.js Dockerfile:

```dockerfile
# Dockerfile — based on Next.js production best practices
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN corepack enable && pnpm build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
EXPOSE 3000
CMD ["node", "server.js"]
```

Add to `next.config.mjs`: `output: 'standalone'`.

### docker-compose.yml

```yaml
services:
  payload:
    build: .
    ports:
      - "3000:3000"
    environment:
      DATABASE_URI: postgresql://payload:${DB_PASSWORD}@postgres:5432/payload
      PAYLOAD_SECRET: ${PAYLOAD_SECRET}
      NEXT_PUBLIC_SERVER_URL: https://cms.example.com
      # S3 storage (if using @payloadcms/storage-s3)
      S3_BUCKET: ${S3_BUCKET}
      S3_REGION: ${S3_REGION}
      S3_ACCESS_KEY_ID: ${S3_ACCESS_KEY_ID}
      S3_SECRET_ACCESS_KEY: ${S3_SECRET_ACCESS_KEY}
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: payload
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: payload
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U payload"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres-data:
```

```bash
cat > .env <<EOF
PAYLOAD_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -hex 16)
S3_BUCKET=my-payload-media
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=...
S3_SECRET_ACCESS_KEY=...
EOF
docker compose build
docker compose up -d
docker compose logs -f payload
```

## Deploy — Vercel + Neon + Vercel Blob

One-click: <https://dub.sh/payload-vercel>. Provisions:

- Next.js app on Vercel (free tier for personal use).
- Neon Postgres (free 0.5GB tier).
- Vercel Blob (free tier for uploads).

Env vars `DATABASE_URI` + `BLOB_READ_WRITE_TOKEN` + `PAYLOAD_SECRET` auto-configured.

## Deploy — Cloudflare Workers + D1 + R2

One-click: <https://dub.sh/payload-cloudflare>. Provisions:

- Cloudflare Worker running the Next.js app.
- D1 (SQLite) database.
- R2 for uploads.

Uses the `@payloadcms/db-sqlite` adapter + `@payloadcms/storage-r2`. Globally replicated; good for read-heavy sites.

## Database adapters

| Adapter package | DB | Notes |
|---|---|---|
| `@payloadcms/db-postgres` | Postgres 13+ | Upstream recommendation. Uses Drizzle. |
| `@payloadcms/db-mongodb` | MongoDB 5+ | Original Payload adapter; pre-v3. |
| `@payloadcms/db-sqlite` | SQLite / D1 | Small-site friendly; Cloudflare path uses this. |
| `@payloadcms/db-vercel-postgres` | Vercel Postgres | Thin wrapper around db-postgres. |

Switching adapters post-launch requires data migration — not plug-and-play.

## Storage adapters (uploads)

| Package | Storage | When |
|---|---|---|
| `@payloadcms/storage-s3` | AWS S3 / any S3-compatible (R2, MinIO, Wasabi, etc.) | Self-host with object storage. |
| `@payloadcms/storage-vercel-blob` | Vercel Blob | Vercel-hosted. |
| `@payloadcms/storage-r2` | Cloudflare R2 | CF Workers path. |
| `@payloadcms/storage-azure` | Azure Blob | Azure-hosted. |
| `@payloadcms/storage-gcs` | Google Cloud Storage | GCP-hosted. |
| Local FS (default) | `./media/` | Dev only; doesn't scale beyond one node. |

## Upgrade procedure

```bash
# Payload follows Next.js release cadence.
pnpm update payload @payloadcms/* next@latest

# Regenerate types (Payload generates TS types for your collections)
pnpm payload generate:types

# Run DB migrations (Drizzle for Postgres / SQLite)
pnpm payload migrate

# Rebuild + restart
pnpm build
# Docker: docker compose build && docker compose up -d
```

Payload's v3 (released 2024) was a major rewrite that bundled it into Next.js. Upgrades within v3 are usually smooth; v2 → v3 required a big migration — see <https://payloadcms.com/docs/migration/overview>.

## Gotchas

- **Payload IS a Next.js app.** If your team isn't comfortable with Next.js / React Server Components, the learning curve is steeper than "headless CMS." For pure headless (API + admin UI, no frontend), Directus / Strapi are more traditional fits.
- **No standalone image.** Self-host = "your Next.js app happens to have Payload in it." Backup plan = your app's code + the Postgres DB + the uploads storage.
- **`PAYLOAD_SECRET` is critical.** Used for JWT signing AND encrypted-field encryption. Rotating it invalidates all sessions AND corrupts encrypted-field data. Treat like a DB encryption key.
- **First admin user is whoever signs up first.** At `/admin` on a fresh install, the first POST to `/admin/create-first-user` wins. Firewall or gate this endpoint until you've claimed it.
- **Local FS storage doesn't scale.** Fine for dev; in production, switch to S3/R2/Vercel Blob from day one. Moving later requires a migration script.
- **Database adapter is baked into build.** You can't flip between Postgres / MongoDB / SQLite at runtime — it's determined at `payload.config.ts` compile time.
- **Rich text is Lexical (v3+)**, not Slate. Old v2 Slate data needs migration via `@payloadcms/richtext-converter-lexical`. Silent breakage otherwise.
- **Access control runs on every query.** If you write heavy access-control functions (DB lookups inside `access: () => ...`), you'll see latency. Benchmark before shipping.
- **Email is opt-in.** Until you configure `email` in `payload.config.ts` (Nodemailer / Resend / SendGrid), `/forgot-password` and email verification silently no-op.
- **TypeScript types are generated.** Run `pnpm payload generate:types` after changing collections; otherwise IDE + runtime drift.
- **Dev mode is SLOW with lots of collections.** Turbopack helps; plan for `.next/cache` and ~2 GB RAM during `next dev`.
- **Security of the admin panel.** No built-in rate limiting on the login endpoint. Put it behind a reverse proxy with rate limits / fail2ban, or use IP allowlisting for the `/admin` path.
- **Next.js Standalone output is required for Docker.** `next.config.mjs: output: 'standalone'` — without it, Docker images are 3× bigger and copy broken paths.
- **No official Helm chart.** K8s deploys are DIY — wrap the standalone Next.js build in a Deployment + Service + Ingress.

## Links

- Upstream repo: <https://github.com/payloadcms/payload>
- Docs: <https://payloadcms.com/docs>
- Installation: <https://payloadcms.com/docs/getting-started/installation>
- Database adapters: <https://payloadcms.com/docs/database/overview>
- Storage adapters: <https://payloadcms.com/docs/upload/storage-adapters>
- Authentication: <https://payloadcms.com/docs/authentication/overview>
- Access control: <https://payloadcms.com/docs/access-control/overview>
- Templates: <https://github.com/payloadcms/payload/tree/main/templates>
- Releases: <https://github.com/payloadcms/payload/releases>
- Discord: <https://discord.gg/payload>
