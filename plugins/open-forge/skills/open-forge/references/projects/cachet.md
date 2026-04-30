---
name: Cachet
description: Open-source status-page system — publish component health, incidents, scheduled maintenance, metrics, and subscriber notifications. Laravel (PHP). BSD-3-Clause. Currently between 2.4 (stable/Docker-supported) and 3.x (in active development / rewritten).
---

# Cachet

Cachet is a self-hosted status page (the "statuspage.io alternative") — a public-facing site that shows the live health of your services, active incidents, scheduled maintenance, historical uptime, and optional metrics graphs. Users subscribe via email / webhook / Slack to incident updates.

**Upstream is mid-transition.** Cachet 2.x (stable) is feature-complete but infrastructure is older (PHP 7.x, dated Laravel). Cachet 3.x (active dev, beta-labeled) is a full rewrite on Laravel 11 / PHP 8.2+ with a modern admin UI — but **no Docker support yet** (the upstream `cachethq/Docker` repo is explicitly for 2.x).

This recipe covers both.

- Upstream repo (3.x, default): <https://github.com/cachethq/cachet>
- Docker repo (2.x only): <https://github.com/cachethq/Docker>
- Docs: <https://docs.cachethq.io>
- Image (2.x): `cachethq/docker` on Docker Hub

## Compatible install methods

| Infra       | Runtime                                           | Version | Notes                                                                   |
| ----------- | ------------------------------------------------- | ------- | ----------------------------------------------------------------------- |
| Single VM   | Docker Compose (`cachethq/Docker` 2.x path)       | 2.4     | **Most deployable today** if you're OK running the 2.x line             |
| Single VM   | Composer + PHP 8.2+ + MySQL/Postgres/SQLite       | 3.x     | **Upstream-recommended for 3.x** — no Docker yet                         |
| Kubernetes  | Community charts (2.x) / Hand-rolled (3.x)        | Either  | No official 3.x Docker image                                            |
| Managed     | cachethq.io (commercial hosted v3)                | 3.x     | Upstream-hosted; commercial                                             |

## Inputs to collect

| Input                | Example                            | Phase    | Notes                                                                   |
| -------------------- | ---------------------------------- | -------- | ----------------------------------------------------------------------- |
| Public URL           | `https://status.example.com`       | Runtime  | `APP_URL`; baked into emails + subscribe links                          |
| `APP_KEY`            | auto-generated via `php artisan`   | Runtime  | Required; lose it = lose session / encrypted-setting decryption          |
| DB backend           | PostgreSQL / MySQL / MariaDB / SQLite / SQL Server (3.x) | DB | 3.x added SQLite + SQL Server support                            |
| DB credentials       | strong password                    | DB       | Default `postgres/postgres` in 2.x compose — change immediately          |
| Admin account        | created during setup               | Bootstrap | 3.x: `php artisan cachet:make:user`; 2.x: web wizard                     |
| SMTP                 | any provider                       | Runtime  | For subscriber notifications + password reset                           |
| Scheduler cron       | `* * * * * php artisan schedule:run` | Runtime | Required for scheduled tasks (metric aggregation, cleanups)             |

## Install Cachet 2.x via Docker Compose

From <https://github.com/cachethq/Docker>:

```sh
git clone https://github.com/cachethq/Docker.git cachet-docker
cd cachet-docker

# 1. Generate an app key:
docker run --rm cachethq/docker:2.4 php artisan key:generate --show
# Copy the resulting base64:... string

# 2. Edit docker-compose.yml:
#    - set APP_KEY=<generated key> (replace ${APP_KEY:-null})
#    - set POSTGRES_PASSWORD + DB_PASSWORD to a strong matching value
#    - set cachet_ver ARG to a pinned release tag (not 'main')

# 3. Start:
docker compose up --build -d
```

The `cachet` container runs on port 8000 internally; the compose maps it to host port 80. Browse `http://<host>` — the web installer runs on first visit (asks for admin account + basic settings).

### Pin the Cachet version

The upstream compose hard-codes `cachet_ver=2.4` at build time. **Never change this to `main` for production** — upstream explicitly warns that the `main` branch and `cachethq/docker:latest` are "a work in progress / development version" not for production.

## Install Cachet 3.x manually (recommended for new deploys in 2025+)

From <https://docs.cachethq.io/v3.x/installation>:

```sh
# 1. Prereqs: PHP 8.2/8.3/8.4 + Composer + your chosen DB
# 2. Clone
git clone -b 3.x https://github.com/cachethq/cachet.git
cd cachet

# 3. Install dependencies
composer install --no-dev -o
composer update cachethq/core         # temporary step until 3.x is released

# 4. Configure
cp .env.example .env
php artisan key:generate
# Edit .env: DB_*, APP_URL, MAIL_*, QUEUE_CONNECTION, etc.

# 5. Publish assets + run migrations
php artisan vendor:publish --tag=cachet
php artisan migrate

# 6. Create first admin user
php artisan cachet:make:user

# 7. Set up web server (nginx / Apache) pointing at /path/to/cachet/public/
# 8. Add scheduler cron:
#    * * * * * php /path/to/cachet/artisan schedule:run >> /dev/null 2>&1

# 9. Run queue worker (systemd / supervisord):
#    php /path/to/cachet/artisan queue:work
```

## Data & config layout

- `.env` — all runtime config (DB, SMTP, APP_URL, APP_KEY)
- `database/database.sqlite` (SQLite only) — all data
- DB (Postgres/MySQL) — components, incidents, users, subscribers, metrics
- `storage/` — uploaded logos, attachments
- `bootstrap/cache/` — cached config / routes (rebuild on upgrade)

## Backup

```sh
# SQL databases
docker compose exec -T postgres pg_dump -U postgres postgres | gzip > cachet-db-$(date +%F).sql.gz
# SQLite
cp database/database.sqlite cachet-db-$(date +%F).sqlite

# .env + storage/
tar czf cachet-misc-$(date +%F).tgz .env storage/
```

## Upgrade

### 2.x in Docker

1. Update `cachet_ver` ARG in `docker-compose.yml` to the newer release tag.
2. `docker compose build && docker compose up -d` — migrations run on container start.

### 2.x → 3.x

Cachet 3.x is a rewrite on Laravel 11. Upgrading from 2.x = run the 3.x migration tool: <https://docs.cachethq.io/v3.x/migration-guide>. Not a trivial in-place upgrade; plan a migration window.

### 3.x

1. `git pull origin 3.x`
2. `composer install --no-dev -o`
3. `php artisan migrate --force`
4. `php artisan vendor:publish --tag=cachet --force`
5. Restart web server + queue worker.

## Gotchas

- **Pick your version carefully.** Cachet 3.x is labeled "in development" in official install docs; the rewrite is underway but not yet marked production-stable. Cachet 2.x still works and has a Docker image but is feature-frozen. Decide based on your risk appetite.
- **`main` branch + `latest` tag = unstable.** Upstream Docker README explicitly warns: *"main or latest should not be used in a production environment as it can change at anytime."* Pin to release tags.
- **Default `APP_KEY=${APP_KEY:-null}`** in the 2.x compose must be replaced with a real generated key. `null` works on first boot (generates one) but the value is not persisted, so the next container restart generates a new one → sessions invalidate + encrypted settings become unreadable.
- **2.x is on PHP 7.x** which is EOL. Security patches from Cachet ship, but the underlying PHP+Laravel versions no longer get upstream security updates. Plan the 3.x migration.
- **Demo credentials `test@test.com / test123`** are publicly documented and occasionally find their way into production setups accidentally. First action after install: change.
- **No built-in TLS.** Behind Caddy / Traefik / nginx. Set `APP_URL=https://...` to match.
- **Scheduler cron is not optional.** Without `schedule:run` every minute, metric aggregation + historical uptime calculation + subscriber-notification digest jobs stop running. Cachet looks "alive" but historical graphs stop updating.
- **Queue worker** (3.x): Cachet 3.x uses Laravel queues for email notifications. Without `queue:work`, subscribers never get incident emails.
- **Subscribers can be SMS/webhook/Slack, not just email.** 3.x expanded notification channels significantly — configure per-channel secrets in admin.
- **Metrics rendering is heavy.** Each metric chart runs an SQL aggregation on each page load by default. Large datasets need caching enabled via `CACHE_DRIVER=redis` in `.env`.
- **API (v1 REST) is stable.** External integrations can push component status + incidents via API token. Invaluable for automation: cron jobs check your own services + push status updates to Cachet.
- **No multi-tenant out of the box.** One Cachet instance = one status page. For multiple pages (e.g. per region), run multiple instances or wait for 3.x multi-brand features.
- **Sponsor-supported open source.** Cachet is maintained by jump24.co.uk and contributors; funding is sponsor-based. Development pace varies.

## Links

- Repo (3.x): <https://github.com/cachethq/cachet>
- Docker repo (2.x): <https://github.com/cachethq/Docker>
- Docs: <https://docs.cachethq.io>
- 3.x installation: <https://docs.cachethq.io/v3.x/installation>
- 2.x → 3.x migration: <https://docs.cachethq.io/v3.x/migration-guide>
- 3.x announcement: <https://github.com/CachetHQ/Cachet/discussions/4342>
- Releases: <https://github.com/cachethq/cachet/releases>
- Docker Hub: <https://hub.docker.com/r/cachethq/docker>
- Demo (v3): <https://v3.cachethq.io/dashboard>
- Commercial hosting: <https://cachethq.io>
