---
name: shelf
description: Shelf recipe for open-forge. Covers Docker (community-supported) with required Supabase backend. Shelf is an open-source asset and equipment tracking platform with QR labels, bookings, custody tracking, and team roles.
---

# Shelf

Open-source asset and equipment tracking platform. Teams use it to track physical assets — equipment, devices, tools, vehicles — with QR asset labels, custody assignment, booking/reservation calendar, location hierarchy, custom fields, and role-based access. Upstream: <https://github.com/Shelf-nu/shelf.nu>. Docs: <https://docs.shelf.nu>.

**License:** AGPL-3.0 · **Language:** Node.js (React Router / Remix + TypeScript) · **Default port:** 3000 · **Stars:** ~2,600

> **Important:** Shelf requires a **Supabase** project (PostgreSQL + Auth + Storage). There is no fully standalone self-hosted path without Supabase. You can use Supabase Cloud (free tier works) or self-host Supabase separately.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (`ghcr.io/shelf-nu/shelf.nu`) | <https://docs.shelf.nu/docker> | Community-supported | Containerized deploy — still requires external Supabase. |
| Fly.io (CI/CD) | <https://docs.shelf.nu/deployment> | ✅ | Official upstream deploy target — Fly.io + GitHub Actions. |
| Local dev / source | <https://docs.shelf.nu/local-development> | ✅ | Development or custom build. |

> **Note:** Docker support is community-contributed, not officially maintained by Shelf Inc. Use at your own risk and check GitHub issues for known Docker-specific bugs.

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| supabase | "Supabase project URL and anon/service-role keys? (Create project at supabase.com if needed)" | Free-text (sensitive) | All methods. |
| database_url | "Supabase PostgreSQL connection string (DATABASE_URL + DIRECT_URL)?" | Free-text (sensitive) | All methods. |
| domain | "What URL will Shelf be served at?" | Free-text | Docker / Fly.io. |
| session_secret | "SESSION_SECRET (random 32+ char string)?" | Free-text (sensitive) | All methods. |
| smtp | "SMTP host, port, user, password for email notifications?" | Free-text (sensitive) | Optional but recommended. |

## Prerequisite: Supabase setup

Reference: <https://docs.shelf.nu/supabase-setup>

1. Create a Supabase project at <https://supabase.com> (or self-host Supabase).
2. In Project Settings → API, collect:
   - `Project URL` → `SUPABASE_URL`
   - `anon public` key → `SUPABASE_ANON_PUBLIC_KEY`
   - `service_role` key → `SUPABASE_SERVICE_ROLE_KEY`
3. In Project Settings → Database → Connection string, collect the pooler + direct URLs → `DATABASE_URL` and `DIRECT_URL`.
4. Run Prisma migrations (required before first start):
   ```bash
   git clone https://github.com/Shelf-nu/shelf.nu.git
   cd shelf.nu
   cp .env.example .env
   # Fill in .env with Supabase credentials
   pnpm install
   pnpm webapp:setup   # runs prisma generate + migrate deploy
   ```
5. Configure Supabase Auth: enable Email provider, set Site URL to your Shelf domain.
6. Configure Supabase Storage: create a bucket named `profile-pictures` and `assets` (or follow the setup guide).

## Install — Docker

Reference: <https://docs.shelf.nu/docker>

```bash
docker run -d \
  --name shelf \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e DATABASE_URL="postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres?pgbouncer=true" \
  -e DIRECT_URL="postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres" \
  -e SESSION_SECRET="<random-32-char-secret>" \
  -e SUPABASE_URL="https://yourproject.supabase.co" \
  -e SUPABASE_ANON_PUBLIC_KEY="<anon-public-key>" \
  -e SUPABASE_SERVICE_ROLE_KEY="<service-role-key>" \
  -e SERVER_URL="https://shelf.example.com" \
  ghcr.io/shelf-nu/shelf.nu:latest
```

Or with Docker Compose — create `docker-compose.yml`:

```yaml
services:
  shelf:
    image: ghcr.io/shelf-nu/shelf.nu:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      DATABASE_URL: "${DATABASE_URL}"
      DIRECT_URL: "${DIRECT_URL}"
      SESSION_SECRET: "${SESSION_SECRET}"
      SUPABASE_URL: "${SUPABASE_URL}"
      SUPABASE_ANON_PUBLIC_KEY: "${SUPABASE_ANON_PUBLIC_KEY}"
      SUPABASE_SERVICE_ROLE_KEY: "${SUPABASE_SERVICE_ROLE_KEY}"
      SERVER_URL: "https://shelf.example.com"
      SMTP_HOST: "${SMTP_HOST}"
      SMTP_PORT: "${SMTP_PORT}"
      SMTP_USER: "${SMTP_USER}"
      SMTP_PWD: "${SMTP_PWD}"
      SMTP_FROM: "Shelf <noreply@example.com>"
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Supabase | Required external dependency — PostgreSQL DB, Auth (email/SSO), and Storage (file uploads). No embedded alternative. |
| DATABASE_URL | Use the **pooler** (pgBouncer) connection string for the app — handles connection pooling. |
| DIRECT_URL | Use the **direct** (non-pooler) connection for Prisma migrations. |
| SESSION_SECRET | Must be a strong random string. Used to sign session cookies — do not rotate on running installs without invalidating all sessions. |
| Migrations | Must run `prisma migrate deploy` against the Supabase DB before starting the app. Do this once at initial setup and after upgrades. |
| File storage | Supabase Storage handles asset attachments and profile pictures. Configure bucket policies per upstream docs. |
| Email | SMTP config required for invitation emails, password reset, and asset reminders. |
| ARM64 | Multi-arch image available (amd64 + arm64). |
| Port | Default 3000. Put behind nginx/Caddy with TLS — required for production. |

## Upgrade procedure

```bash
# Pull latest image
docker pull ghcr.io/shelf-nu/shelf.nu:latest

# Run migrations first (use a temporary container with the same env)
docker run --rm \
  -e DATABASE_URL="$DATABASE_URL" \
  -e DIRECT_URL="$DIRECT_URL" \
  ghcr.io/shelf-nu/shelf.nu:latest \
  pnpm db:deploy-migration

# Restart the app container
docker compose up -d
```

## Gotchas

- **Supabase is mandatory:** There is no path to run Shelf without Supabase. The app tightly integrates with Supabase Auth, Supabase Storage, and Supabase Realtime. If you want a fully air-gapped deploy, you'd need to self-host Supabase too.
- **Docker is community-supported:** The upstream team primarily supports Fly.io deploys. Docker image bugs may take longer to be addressed. Check <https://github.com/Shelf-nu/shelf.nu/issues> for Docker-specific issues.
- **Run migrations before starting:** If you start the container without running Prisma migrations against your Supabase DB, the app will crash on first request. Run `pnpm db:deploy-migration` or use the migration container step above.
- **Supabase Auth site URL:** Must be set to your exact Shelf domain in Supabase Dashboard → Authentication → URL Configuration → Site URL. Wrong value breaks magic links and OAuth callbacks.
- **DIRECT_URL vs DATABASE_URL:** pgBouncer (pooler) doesn't support prepared statements used by Prisma migrations. Always use the direct connection URL for migrations and the pooler URL for the running app.

## Upstream links

- GitHub: <https://github.com/Shelf-nu/shelf.nu>
- Documentation: <https://docs.shelf.nu>
- Supabase setup guide: <https://docs.shelf.nu/supabase-setup>
- Docker setup guide: <https://docs.shelf.nu/docker>
- Deployment (Fly.io): <https://docs.shelf.nu/deployment>
- Docker image: `ghcr.io/shelf-nu/shelf.nu:latest`
