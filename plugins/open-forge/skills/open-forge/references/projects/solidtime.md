---
name: Solidtime
description: "Modern open-source time tracker for freelancers and agencies. Projects, tasks, clients, billable rates, multi-org, roles/permissions, Toggl/Clockify import. Laravel 11 + Vue 3 + Postgres + Redis. AGPL-3.0."
---

# Solidtime

Solidtime is a **modern, self-hostable time tracker** aimed squarely at **freelancers and agencies**. It's the OSS answer to Toggl Track, Harvest, Clockify — with a clean, modern UI (Vue 3 + Tailwind), strong multi-org support, and reasonable built-in billing features (project/member/org billable rates).

Features:

- **Time tracking** — start/stop timer, manual entry, calendar view
- **Projects** — with assigned members + budgets + billable rates
- **Tasks** — per-project, optional
- **Clients** — assign to projects; invoicing context
- **Billable rates** — per project, per project-member, per org-member, org-default; hierarchical override
- **Multiple organizations** per account — switch between personal, agency A, agency B
- **Roles + permissions** — owner / admin / manager / employee / placeholder
- **Import** — Toggl, Clockify, time-entry CSV
- **Reports** — by project / client / user / date range; CSV/PDF export
- **API + webhooks** for automation
- **Stopwatch / time-entry editing** with full history
- **Dashboard** with stats

**Note**: the repo author explicitly states "AI-slop PRs get you banned" — this is a real project with a real human maintainer (not an AI content farm). Respect the contribution guidelines.

- Upstream repo: <https://github.com/solidtime-io/solidtime>
- Website: <https://www.solidtime.io>
- Docs: <https://docs.solidtime.io>
- Self-hosting guides: <https://docs.solidtime.io/self-hosting/intro>
- Self-hosting examples: <https://github.com/solidtime-io/self-hosting-examples>
- Cloud: <https://app.solidtime.io>

## Architecture in one minute

- **Backend**: Laravel 11 (PHP 8.3+)
- **Frontend**: Vue 3 + Inertia.js + Tailwind
- **DB**: Postgres 14+ (primary) — MySQL support exists but Postgres is the recommended path
- **Cache + queue**: Redis
- **Queue worker**: Laravel Horizon
- **Mailer**: any Laravel-supported (SMTP, SES, Mailgun, Postmark)
- **Storage**: local disk or S3-compatible (for PDF exports, avatars)
- **Reverse proxy** required for TLS

## Compatible install methods

| Infra       | Runtime                                          | Notes                                                           |
| ----------- | ------------------------------------------------ | --------------------------------------------------------------- |
| Single VM   | **Docker Compose** (examples repo)                  | **The way**                                                        |
| Single VM   | Native LEMP (PHP 8.3 + Postgres + Redis + nginx)       | Doable but more moving parts                                               |
| Managed     | Solidtime Cloud (`app.solidtime.io`)                        | If you don't want ops                                                          |
| Kubernetes  | Community Helm/manifests                                       | Examples exist in examples repo                                                    |

## Inputs to collect

| Input             | Example                         | Phase     | Notes                                                           |
| ----------------- | ------------------------------- | --------- | --------------------------------------------------------------- |
| Domain            | `time.example.com`                | URL       | `APP_URL` in Laravel .env                                             |
| DB                | Postgres user/pass/db               | DB        | Postgres 14+                                                                 |
| Redis             | localhost or dedicated                | Cache     | Sessions + queue                                                                       |
| Admin user        | register via first-boot                 | Bootstrap | First user becomes org owner                                                                    |
| SMTP              | host + port + creds                       | Email     | Invites, password reset, report delivery                                                                   |
| S3 (opt)          | bucket + creds                              | Storage   | For PDF exports + avatars                                                                                    |
| APP_KEY           | Laravel artisan-generated                     | Crypto    | Set before boot; don't rotate after                                                                                 |

## Install via Docker Compose

The `self-hosting-examples` repo is the canonical source. Outline:

```yaml
services:
  solidtime:
    image: solidtime/solidtime:0.12.1   # pin; check Docker Hub / GHCR
    container_name: solidtime
    restart: unless-stopped
    depends_on:
      db: { condition: service_healthy }
      redis: { condition: service_started }
    ports:
      - "8080:8080"
    environment:
      APP_URL: https://time.example.com
      APP_KEY: base64:<run-php-artisan-key-generate>
      DB_CONNECTION: pgsql
      DB_HOST: db
      DB_PORT: "5432"
      DB_DATABASE: solidtime
      DB_USERNAME: solidtime
      DB_PASSWORD: <strong>
      REDIS_HOST: redis
      MAIL_MAILER: smtp
      MAIL_HOST: smtp.example.com
      MAIL_PORT: "587"
      MAIL_USERNAME: no-reply@example.com
      MAIL_PASSWORD: <smtp-pass>
      MAIL_FROM_ADDRESS: no-reply@example.com
      MAIL_FROM_NAME: Solidtime
      QUEUE_CONNECTION: redis
      SESSION_DRIVER: redis
      CACHE_DRIVER: redis
    volumes:
      - solidtime-storage:/var/www/html/storage

  # Run migrations + queue worker + scheduler in companion containers if image doesn't bundle
  # (check upstream compose for exact topology — may bundle Horizon/scheduler inside main container via supervisord)

  db:
    image: postgres:16-alpine
    container_name: solidtime-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: solidtime
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: solidtime
    volumes:
      - solidtime-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U solidtime"]
      interval: 10s

  redis:
    image: redis:7-alpine
    container_name: solidtime-redis
    restart: unless-stopped
    volumes:
      - solidtime-redis:/data

volumes:
  solidtime-db:
  solidtime-redis:
  solidtime-storage:
```

Browse `https://time.example.com` → register first user → becomes org owner.

## First boot

1. Register → create organization
2. Organization Settings → set timezone, default billable rate, currency
3. Add clients → add projects per client → invite team members
4. Start the timer on a project (top-right stopwatch)
5. End of day: review entries → mark as billable → generate report
6. Reports → filter by date range / project / client → export CSV/PDF

## Imports

Settings → Import → pick source:

- **Toggl Track** — upload CSV export
- **Clockify** — upload CSV export
- **Generic time-entry CSV** — column mapping wizard

## Data & config layout

- `.env` — app config + secrets
- Postgres — all users, orgs, projects, time entries, rates
- Redis — sessions + queue + cache
- `storage/app/` — file uploads (avatars, exported PDFs)

## Backup

```sh
# DB (CRITICAL — all time entries)
docker exec solidtime-db pg_dump -U solidtime solidtime | gzip > solidtime-$(date +%F).sql.gz

# Storage (smaller but includes PDFs if not on S3)
docker run --rm -v solidtime_solidtime-storage:/src -v "$(pwd):/backup" alpine \
  tar czf /backup/solidtime-storage-$(date +%F).tgz -C /src .
```

## Upgrade

1. Releases: <https://github.com/solidtime-io/solidtime/releases>. Active.
2. Back up DB first.
3. Docker: bump image tag → `docker compose pull && docker compose up -d`. Laravel migrations auto-run.
4. Read CHANGELOG for breaking changes — Solidtime is pre-1.0 in some respects; expect iteration.

## Gotchas

- **Active but young project** — quick iteration + occasional breaking changes. Pin image versions; don't run `latest`.
- **AI-generated PRs explicitly banned** — this is a real-person project. Don't submit AI-slop contributions; read CONTRIBUTING.md before opening PRs. Features arrive at the maintainer's pace.
- **Postgres is preferred** — MySQL "works" but the team tests Postgres. Use Postgres unless you have a hard reason not to.
- **Time zones matter** — especially for agencies with team members across zones. Solidtime handles TZ, but users should set their own TZ per profile for accurate reports.
- **Billable rate hierarchy**: org default → member default → project default → project member. Understand the override order before setting rates to avoid surprise billing.
- **Tasks are optional** — you can track time against a project without creating tasks. Good for small projects; larger teams benefit from tasks for categorization.
- **No invoicing built in** — Solidtime tracks time + rates; it doesn't generate invoices or sync to QuickBooks/Xero/Stripe invoicing. Use a separate tool (Akaunting, Invoice Ninja, FreshBooks) to turn reports into invoices.
- **No idle detection** on the desktop — Solidtime is web-based (unlike Toggl's desktop apps that auto-detect idle). If you step away with the timer running, it keeps running.
- **No native desktop/mobile apps yet** — the web app is responsive + PWA-installable, but no native apps as of writing.
- **Keyboard shortcuts** — UI is web; check docs for shortcut list; may be sparse vs Toggl's desktop apps.
- **Solidtime Cloud** is the upstream-blessed hosted version — supports development. Reasonable if self-hosting ops aren't your thing.
- **Multi-org** = one user, N organizations. Useful for solo freelancers who contract to multiple agencies. Time entries belong to one org each.
- **Horizon** (Laravel queue dashboard) — worth exposing internally for queue monitoring, with admin-only auth via reverse proxy.
- **Scheduled tasks** — `php artisan schedule:run` must run every minute (container / cron). Without it, reports + cleanups don't happen.
- **Browser timer**: runs client-side; if you close the tab, the entry is still saved (backed by DB). Restoring continues from where it left off.
- **SSO / OIDC**: not front-and-center as of writing; check latest docs. Reverse-proxy-level auth works (Authentik, Authelia in front).
- **Exports**: CSV always; PDF for formatted reports; limited customization of PDF layout.
- **Reports are powerful** but require a bit of learning — grouped by project vs client vs user; billable vs all.
- **AGPL-3.0** — strong copyleft; network-use counts; modifying + hosting for others requires source disclosure.
- **Alternatives worth knowing:**
  - **Kimai** — PHP/Symfony; mature OSS time tracker; similar target audience; more plugin ecosystem (separate recipe)
  - **Traggo** — Go; minimal; tag-based time tracking
  - **Timetagger** — single-person; simple
  - **Leantime** — project management + time tracking bundled (separate recipe)
  - **Toggl Track / Harvest / Clockify / TimeCamp** — SaaS
  - **RescueTime** — automatic tracking based on app usage
  - **Hubstaff / TimeDoctor** — surveillance-grade employee monitoring (different use case)
  - **Choose Solidtime if:** you want a **modern, polished OSS time tracker** with strong multi-org + billable-rate features.
  - **Choose Kimai if:** you want the most mature OSS time tracker with bigger feature set + plugin ecosystem.
  - **Choose Clockify Cloud if:** you want the most features in a generous free tier and don't need self-hosting.

## Links

- Repo: <https://github.com/solidtime-io/solidtime>
- Website: <https://www.solidtime.io>
- Cloud: <https://app.solidtime.io>
- Docs: <https://docs.solidtime.io>
- Self-hosting intro: <https://docs.solidtime.io/self-hosting/intro>
- Examples repo: <https://github.com/solidtime-io/self-hosting-examples>
- Contributing: <https://github.com/solidtime-io/solidtime/blob/main/CONTRIBUTING.md>
- Security policy: <https://github.com/solidtime-io/solidtime/blob/main/SECURITY.md>
- Docs repo: <https://github.com/solidtime-io/docs>
- Releases: <https://github.com/solidtime-io/solidtime/releases>
- Docker image: <https://github.com/solidtime-io/solidtime/pkgs/container/solidtime>
- Discussions: <https://github.com/solidtime-io/solidtime/discussions>
