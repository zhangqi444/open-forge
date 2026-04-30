---
name: Chartbrew
description: "Open-source web app to connect databases + APIs and build interactive charts, dashboards, and embeddable visualizations. Chart builder, query editor, team collaboration. Node.js + React. License: custom (source-visible; commercial SaaS at chartbrew.com)."
---

# Chartbrew

Chartbrew is **"a Metabase / Redash / Superset alternative in a lighter wrapper"** — an open-source web app that connects to your databases + REST APIs, lets you build charts with a visual + query editor, assemble them into dashboards, and embed individual charts in other sites. Team collaboration (projects + users), editable dashboards, request builder for APIs, Google/Facebook OAuth sources, and a **hosted SaaS** at <https://chartbrew.com> that funds the OSS version.

Built + maintained by **razvanilin (Razvan Ilin)** + community contributors (Chartbrew org). **License**: upstream `package.json` reports a custom arrangement (GitHub API returns `NOASSERTION`) — **review `LICENSE` in the repo before commercial deployment**. Community-usable for self-host; SaaS version sustains development.

Use cases: (a) **business-intelligence-lite** without deploying a Metabase/Superset stack (b) **API data visualization** — Stripe + HubSpot + custom REST APIs → charts (c) **embeddable charts** in customer-facing pages (d) **small-team dashboards** for internal metrics (e) **startup founder's quick dashboard** (Razvan's origin story).

Features:

- **Data sources**: PostgreSQL, MySQL, MongoDB, REST APIs, Google Analytics, Firestore, custom (latest list on <https://chartbrew.com>)
- **Visual chart builder** — no SQL required for simple cases
- **SQL + request editors** — raw queries when needed
- **Dashboards** — drag-and-drop layouts
- **Embeddable charts** — iframe / direct embed with auth tokens
- **Teams** — shared projects, role-based access
- **OAuth connectors** — Google, Facebook, generic OIDC
- **Scheduled data refresh**
- **Alerts** (check current status)
- **1-click DigitalOcean droplet**
- **Docker + Docker Compose** deploy

- Upstream repo: <https://github.com/chartbrew/chartbrew>
- Homepage + managed SaaS: <https://chartbrew.com>
- Docs: <https://docs.chartbrew.com>
- Quickstart: <https://docs.chartbrew.com/quickstart>
- Deployment (Docker): <https://docs.chartbrew.com/deployment/run-on-docker>
- Discord: <https://discord.gg/KwGEbFk>
- Docker image: <https://hub.docker.com/r/razvanilin/chartbrew>
- DigitalOcean marketplace: <https://marketplace.digitalocean.com/apps/chartbrew>

## Architecture in one minute

- **Node.js v20** backend (Express + Sequelize) + **React** frontend
- **MySQL 5+** or **PostgreSQL 12.5+** — metadata DB
- **Redis 6+** — caching + sessions
- **Resource**: modest — 300-700MB RAM typical
- **Ports**: 4018 (frontend default) + 3210 (backend default); unified in Docker

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`razvanilin/chartbrew`** (Docker Hub)                         | **Upstream-primary** — note Docker Hub; watch for registry migrations              |
| Docker Compose     | Upstream quickstart + docs                                                 | Recommended                                                                                |
| DigitalOcean 1-click | Marketplace droplet                                                                           | Fastest trial                                                                                          |
| Bare-metal Node    | `git clone + npm run setup` + systemd                                                                           | For development                                                                                                          |
| Managed SaaS       | <https://chartbrew.com>                                                                                                          | Funds upstream                                                                                                                          |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `charts.example.com`                                        | URL          | TLS required                                                                                    |
| `CB_DB_NAME` + creds | Chartbrew metadata DB                                                   | DB           | MySQL OR Postgres                                                                                    |
| `CB_ENCRYPTION_KEY`  | **32-byte AES key** (`openssl rand -hex 32`)                                                    | Secret       | **IMMUTABLE** — encrypts data-source credentials at rest                                                                                              |
| `CB_API_HOST` + `CB_CLIENT_HOST`                             | Public URLs                                                                     | Config       | Where the UI + API are reachable                                                                                                              |
| Redis                | redis:6-alpine                                                                                       | Cache        | Can be same-container sidecar                                                                                                                      |
| SMTP (opt)           | For notifications                                                                                                    | Email        | Recommended for alerts                                                                                                                                  |
| OAuth client IDs (opt) | Google / Facebook / custom                                                                                                                      | Auth         | For social login if enabled                                                                                                                                                      |

## Install via Docker Compose (outline)

Full guide: <https://docs.chartbrew.com/deployment/run-on-docker>.

```yaml
services:
  chartbrew:
    image: razvanilin/chartbrew:latest         # **pin version** in prod
    restart: unless-stopped
    environment:
      CB_API_HOST: https://api.charts.example.com
      CB_CLIENT_HOST: https://charts.example.com
      CB_DB_NAME: chartbrew
      CB_DB_USERNAME: chartbrew
      CB_DB_PASSWORD: ${DB_PASSWORD}
      CB_DB_HOST: db
      CB_REDIS_HOST: redis
      CB_ENCRYPTION_KEY: ${ENCRYPTION_KEY}     # openssl rand -hex 32
    depends_on: [db, redis]
    ports: ["4018:4018", "3210:3210"]

  db:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: ${ROOT_PW}
      MYSQL_DATABASE: chartbrew
      MYSQL_USER: chartbrew
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes: [mysql:/var/lib/mysql]

  redis:
    image: redis:7-alpine

volumes:
  mysql:
```

## First boot

1. Deploy → browse `CB_CLIENT_HOST` → create admin user
2. Create a team / project
3. Connect first data source: enter connection string → test
4. Build your first chart: query + visualization type
5. Create a dashboard; drag charts in
6. (opt) Enable embed mode for individual charts
7. Put behind TLS reverse proxy
8. Back up metadata DB + ENCRYPTION_KEY

## Data & config layout

- **MySQL / Postgres** — metadata: projects, users, chart definitions, data-source configs (encrypted)
- **Redis** — cache + sessions
- **Data-source credentials**: encrypted in DB with `CB_ENCRYPTION_KEY`; plaintext if key lost
- **Does NOT store your raw data** — queries are executed live against your data sources

## Backup

```sh
# Metadata DB
mysqldump -u root -p chartbrew > chartbrew-$(date +%F).sql
# OR pg_dump for Postgres

# Encryption key (CRITICAL)
cp .env .env-$(date +%F).backup
```

Without `CB_ENCRYPTION_KEY`, encrypted data-source creds are unrecoverable.

## Upgrade

1. Releases: <https://github.com/chartbrew/chartbrew/releases>. Active cadence.
2. Docker: bump tag.
3. Run DB migrations (Chartbrew auto-migrates on boot).
4. Back up FIRST.

## Gotchas

- **`CB_ENCRYPTION_KEY` IMMUTABILITY** — 32-byte AES key encrypts your data-source credentials (DB passwords, API tokens) at rest in the Chartbrew metadata DB. Rotate = lose access to all data sources; must reconnect each one. **Back up separately.** **11th tool** in the immutability-of-secrets family. Crown-jewel tier.
- **Hub-of-credentials crown-jewel** — Chartbrew stores DB connection strings for your Postgres / MySQL / Mongo / every API you connect. **8th tool in the hub-of-credentials family.** Harden:
  - TLS mandatory
  - Network-isolate (VPN / private subnet for internal dashboards)
  - Strong admin password + 2FA if supported
  - Audit access to the metadata DB — anyone with DB read can read ENCRYPTION_KEY-less plaintext once decrypted by the app
- **Review LICENSE in repo** — GitHub API returns `NOASSERTION` for the license field. Upstream is clearly community-friendly (Docker image + compose + self-host docs + Discord) but **if you plan commercial redistribution / SaaS-reselling, read the LICENSE file + Chartbrew's commercial terms before shipping.** The managed SaaS at chartbrew.com may imply specific redistribution restrictions; clarify before betting your product on embedded Chartbrew.
- **Chartbrew does NOT store your raw data.** It queries your data sources live on each refresh. Implications:
  - **Fast response** depends on your source DB performance; slow DB = slow dashboard
  - **No historical snapshots** automatically — what you see reflects current source state
  - **Aggressive auto-refresh can hammer your prod DB** — tune refresh intervals to your DB's capacity. Use read replicas if possible.
- **Credential-at-rest pattern**: encrypted via ENCRYPTION_KEY; decrypted in-memory at query time. If the Chartbrew container is compromised while running, all data-source creds are extractable from memory + env. Same class as any "proxy-to-databases" tool (Metabase, Superset, Redash).
- **Embeddable charts + auth tokens**: when you embed a chart publicly, the underlying query runs against your data source with Chartbrew's creds. **Sanity-check embedded charts can't be manipulated (SQL-injection-style) via URL params.** Chartbrew enforces pre-baked queries but verify for your use-case.
- **Node v20 requirement** — drift matters for bare-metal deploys. Keep Node version current per upstream.
- **Commercial-tier-funds-upstream** pattern — **managed chartbrew.com** SaaS + self-host OSS. Standard "managed-tier" (tier-type #2 in the taxonomy; not feature-gating). DigitalOcean 1-click droplet is another commercial-adjacent path.
- **Alerts / notifications** — check current feature parity between SaaS + self-host; upstream occasionally ships features to SaaS first.
- **OAuth + Google Analytics**: if you integrate Google Analytics, you're subject to Google's OAuth review policies (same class as Easy!Appointments batch 83 → Google Workspace OAuth review-policy risk). Plan for periodic re-review.
- **API-source depth**: Chartbrew's REST API connector is flexible but non-standardized APIs (custom JSON structures, nested pagination) may need client-side transforms. Test with your specific APIs before committing.
- **Team / multi-user scaling**: fine for small-to-mid teams. For 100+ users + RBAC-heavy requirements, evaluate Metabase / Superset (more mature RBAC).
- **Query-performance**: no built-in caching layer beyond Redis session/app cache. For heavy dashboards on expensive queries, consider materialized views in your source DB or a data-warehouse layer between Chartbrew and your operational DB.
- **Project health**: razvanilin + small community + active commits + managed SaaS + Discord + DigitalOcean partnership. Healthy; slower than Metabase/Superset but intentionally simpler.
- **Alternatives worth knowing:**
  - **Metabase** — mature OSS/commercial BI; deeper features; heavier
  - **Apache Superset** — OSS; enterprise-scale BI; complex to operate
  - **Redash** — pre-Apache OSS BI (commercial owner; watch ownership)
  - **Grafana** — metrics/observability-first; can do BI but optimized for time-series
  - **Looker / Tableau / PowerBI** — commercial enterprise
  - **Retool** — internal-tools builder (similar-feel, different scope)
  - **Choose Chartbrew if:** you want lightweight BI + API + DB + self-host + managed-SaaS option + willing to review license.
  - **Choose Metabase if:** you want the mature OSS BI leader + deeper features.
  - **Choose Grafana if:** metrics-first / observability stack.

## Links

- Repo: <https://github.com/chartbrew/chartbrew>
- Homepage + SaaS: <https://chartbrew.com>
- Docs: <https://docs.chartbrew.com>
- Quickstart: <https://docs.chartbrew.com/quickstart>
- Docker deploy: <https://docs.chartbrew.com/deployment/run-on-docker>
- Docker Hub: <https://hub.docker.com/r/razvanilin/chartbrew>
- Discord: <https://discord.gg/KwGEbFk>
- DigitalOcean: <https://marketplace.digitalocean.com/apps/chartbrew>
- Metabase (alt): <https://www.metabase.com>
- Superset (alt): <https://superset.apache.org>
- Redash (alt): <https://redash.io>
- Grafana (alt): <https://grafana.com>
