---
name: Rybbit
description: Open-source, privacy-first web + product analytics. Google-Analytics-without-the-creepy-parts. Page views, sessions, uniques, bounce rate, session duration, session replay, funnels, retention, user journeys. ClickHouse + Postgres + Node.js backend + Next.js client. AGPL-3.0 (self-host) / commercial (Cloud).
---

# Rybbit

Rybbit is a modern open-source analytics platform positioned against Google Analytics 4, Plausible, PostHog, and Umami. Polished dashboards, **session replay**, funnels, retention cohorts, user journey maps — things that Plausible/Umami keep out but Rybbit brings in while staying privacy-friendly (no third-party cookies, no PII without opt-in, self-hosted by default).

- **Web analytics** — pageviews, sessions, uniques, bounce rate, duration, referrers, top pages, etc.
- **Session replay** — record user interactions (rrweb-based); opt-in per-project
- **Funnels** — conversion analysis step-by-step
- **User paths** — Sankey diagrams of user flow
- **Geo maps** — Mapbox-backed (requires a free Mapbox token)
- **Real-time** — live visitor counts + live event feed

Trade-offs vs **PostHog**: lighter, simpler, less product-heavy. Vs **Plausible**: more features (session replay, funnels, paths). Vs **Umami**: much nicer UI + more advanced features but heavier stack (ClickHouse + Postgres + Node.js + Next.js + Caddy, four containers).

- Upstream repo: <https://github.com/rybbit-io/rybbit>
- Website: <https://rybbit.io> (redirects to rybbit.com)
- Docs: <https://rybbit.com/docs>
- Self-hosting: <https://rybbit.com/docs/self-hosting>
- Cloud (free tier): <https://app.rybbit.io>

## Architecture in one minute

- **`rybbit-backend`** — Node.js API + event ingestion
- **`rybbit-client`** — Next.js dashboard (web UI)
- **ClickHouse** — column store for analytics events (pageviews, sessions, clicks, replays)
- **Postgres** — users, orgs, projects, config, auth
- **Caddy** (bundled) — reverse proxy + auto-TLS (optional; can use your own)

## Compatible install methods

| Infra       | Runtime                                               | Notes                                                                |
| ----------- | ----------------------------------------------------- | -------------------------------------------------------------------- |
| Single VM   | Docker Compose with bundled Caddy                     | **Recommended** — upstream's `compose.yml` with profile `with-webserver` |
| Single VM   | Docker Compose behind your own reverse proxy           | Omit `profiles: ["with-webserver"]`                                    |
| Managed     | Rybbit Cloud                                           | <https://rybbit.com/pricing>                                           |
| Kubernetes  | Community (ClickHouse is the complicating part)        | Not upstream-maintained                                                |

## Inputs to collect

| Input                   | Example                                | Phase     | Notes                                                            |
| ----------------------- | -------------------------------------- | --------- | ---------------------------------------------------------------- |
| `DOMAIN_NAME`           | `analytics.example.com`                | DNS       | Used by bundled Caddy for auto-TLS                                 |
| `BASE_URL`              | `https://analytics.example.com`        | Runtime   | Baked into client tracking snippet                                 |
| Postgres creds          | user/pw/db                              | DB        | `POSTGRES_USER`/`POSTGRES_PASSWORD`/`POSTGRES_DB`                   |
| ClickHouse creds        | user/pw/db                              | DB        | `CLICKHOUSE_USER`/`CLICKHOUSE_PASSWORD`/`CLICKHOUSE_DB`              |
| `DISABLE_SIGNUP`        | `true` (after first admin)             | Auth      | Default open; close after admin signup                             |
| `DISABLE_TELEMETRY`     | `false`                                | Privacy   | Opt-out anonymous usage stats                                      |
| `MAPBOX_TOKEN`          | free Mapbox public token               | Optional  | For geo map features                                                |
| `IMAGE_TAG`             | `v0.x.x`                                | Runtime   | Pin; avoid `:latest`                                                |
| First admin             | set on first web visit                 | Bootstrap | First user = admin                                                 |

## Install via Docker Compose (with bundled Caddy)

```sh
git clone https://github.com/rybbit-io/rybbit.git
cd rybbit
cp .env.example .env
# Edit .env: set DOMAIN_NAME + BASE_URL + all creds
docker compose --profile with-webserver up -d
```

`.env` minimum:

```sh
DOMAIN_NAME=analytics.example.com
BASE_URL=https://analytics.example.com
IMAGE_TAG=v0.9.0

POSTGRES_USER=rybbit
POSTGRES_PASSWORD=<strong>
POSTGRES_DB=rybbit

CLICKHOUSE_USER=rybbit
CLICKHOUSE_PASSWORD=<strong>
CLICKHOUSE_DB=analytics

DISABLE_SIGNUP=false     # set true after first admin
DISABLE_TELEMETRY=false
MAPBOX_TOKEN=            # optional
```

Pin image tags via `IMAGE_TAG=v0.9.0` (check <https://github.com/rybbit-io/rybbit/releases>).

## Install behind your own reverse proxy

Drop the `caddy` service (or just don't use `--profile with-webserver`):

```sh
docker compose up -d    # starts backend + client + postgres + clickhouse
```

Then proxy your own domain to **client** on port 3002 (plus backend on 3001 for `/api/*`).

nginx example:

```nginx
upstream rybbit_client  { server 127.0.0.1:3002; }
upstream rybbit_backend { server 127.0.0.1:3001; }

server {
    listen 443 ssl http2;
    server_name analytics.example.com;

    location /api/ {
        proxy_pass http://rybbit_backend;
        proxy_set_header Host $host;
        # ... X-Forwarded-* headers
    }
    location / {
        proxy_pass http://rybbit_client;
        proxy_set_header Host $host;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## First-boot

1. Browse `https://analytics.example.com`
2. Create the admin account (first-user-is-admin)
3. Set `DISABLE_SIGNUP=true` in `.env` + `docker compose up -d` to stop public signups
4. **Create a site** → get `siteId` + the tracking snippet
5. Paste snippet on your website or install via npm (`@rybbit/js`)
6. (Optional) Enable **Session Replay** per-site in Settings → Tracking

## Install the tracking snippet

```html
<script async src="https://analytics.example.com/script.js"
        data-site-id="YOUR_SITE_ID"></script>
```

For SPAs and programmatic tracking, import the JS SDK.

## Data & config layout

- **ClickHouse** (`clickhouse-data` volume): analytics events — pageviews, sessions, clicks, replays. **The big one** — can grow to 100s of GB for high-traffic sites.
- **Postgres** (`postgres-data` volume): users, orgs, projects, site configs, API keys
- **Caddy** (`caddy_data`, `caddy_config` volumes): TLS certs (Let's Encrypt)
- No local filesystem state in the app containers

## Backup

```sh
# Postgres — users, site configs (small, critical)
docker compose exec -T postgres pg_dump -U rybbit rybbit | gzip > rybbit-pg-$(date +%F).sql.gz

# ClickHouse — analytics data (large)
# Use ClickHouse BACKUP command to cloud storage or clickhouse-backup tool:
# https://clickhouse.com/docs/operations/backup

# Caddy certs
docker run --rm -v caddy_data:/src -v "$PWD":/backup alpine tar czf /backup/caddy-$(date +%F).tgz -C /src .
```

For big ClickHouse datasets, set up proper backup tooling (ALTER TABLE FREEZE + object storage, or `clickhouse-backup`), not plain filesystem tar.

## Upgrade

1. Releases: <https://github.com/rybbit-io/rybbit/releases>. v0.x still; expect API churn.
2. Edit `.env` → bump `IMAGE_TAG`.
3. `docker compose pull && docker compose up -d`. Migrations run on startup (Postgres + ClickHouse).
4. **Back up both DBs before every version bump** during 0.x era.
5. ClickHouse major-version jumps (25.4 → 25.5) usually are in-place but test first.

## Gotchas

- **v0.x — expect breaking changes** between minor versions. Pin `IMAGE_TAG`, read release notes before upgrading.
- **ClickHouse is heavy.** Default config sets `mem_reservation: 128g` in the standalone compose — this is for performance, NOT a hard requirement. The bundled compose is more modest. Set ClickHouse memory in its config for small hosts.
- **Session replay = lots of data.** Opt-in per site + configure retention. Don't enable blanket on high-traffic sites without capacity planning.
- **Mapbox token** is optional but required for geo heatmap features. Free tier on Mapbox suffices for most self-hosters.
- **First-user-is-admin.** Set `DISABLE_SIGNUP=true` after bootstrap.
- **Tracking script is public** by design — just a `siteId`, no auth. Anyone who guesses your siteId could inject fake events. Rybbit has server-side filtering but no strong per-site auth on ingest.
- **IP addresses** — Rybbit anonymizes by default (hashed); configure full anonymization in project settings if needed for GDPR compliance.
- **Telemetry**: `DISABLE_TELEMETRY=false` → Rybbit pings back anonymous usage stats. Flip to `true` if you prefer no phone-home.
- **Caddy binds 80/443** in bundled mode; make sure nothing else is listening. If your host already has a reverse proxy, use the non-profile variant.
- **Backend listens on 3001, client on 3002.** Both bind to `127.0.0.1` by default (`HOST_BACKEND_PORT`/`HOST_CLIENT_PORT`) — only reachable via reverse proxy.
- **Dashboard needs modern browser** — Chrome/Firefox/Safari recent; rrweb replay especially is browser-feature-heavy.
- **User-journey Sankey + funnel** views are query-heavy — ClickHouse performance matters. On tiny hosts, expect 5-10s initial loads.
- **No native mobile apps** — web PWA only.
- **AGPL-3.0 + commercial Cloud** — running Rybbit as a SaaS for others = source-sharing obligation.
- **Not a product-analytics suite like PostHog** — no feature flags, no A/B testing, no experiment tracking. For those, use PostHog (heavier, more features) or Growthbook/Unleash (feature flags only).
- **Alternatives worth knowing:**
  - **Plausible** — simpler, 1-container, PostgreSQL+ClickHouse; fewer features, less resource-hungry
  - **Umami** — even simpler, single Node.js + Postgres/MySQL
  - **PostHog** — heavier, "product OS" (flags, experiments, feedback, replay); self-hostable but resource-hungry
  - **Matomo** — mature (formerly Piwik), PHP-based, enterprise-ready
  - **Fathom** — commercial SaaS, privacy-first
  - **GoatCounter** — minimal, Go-based, 1-binary
  - **Simple Analytics / Pirsch** — commercial privacy-first
  - **Ackee** — minimal Node.js + MongoDB

## Links

- Repo: <https://github.com/rybbit-io/rybbit>
- Website: <https://rybbit.com>
- Docs: <https://rybbit.com/docs>
- Self-hosting: <https://rybbit.com/docs/self-hosting>
- Managing installation: <https://rybbit.com/docs/managing-your-installation>
- Pricing: <https://rybbit.com/pricing>
- Releases: <https://github.com/rybbit-io/rybbit/releases>
- Backend image: <https://github.com/rybbit-io/rybbit/pkgs/container/rybbit-backend>
- Client image: <https://github.com/rybbit-io/rybbit/pkgs/container/rybbit-client>
- ClickHouse: <https://clickhouse.com>
- Mapbox: <https://www.mapbox.com>
