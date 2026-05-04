# Saleor

Headless, API-first, GraphQL-native e-commerce platform. Technology-agnostic composable commerce backend for building scalable online stores, marketplaces, and multi-channel retail. BSL 3-Clause. 23K+ GitHub stars. Upstream: <https://github.com/saleor/saleor>. Docs: <https://docs.saleor.io>.

Saleor runs as a Django API backend (port `8000`) + Celery workers, backed by PostgreSQL and Valkey/Redis, with a separate React dashboard (port `9000`). All three components (core, dashboard, storefront) are separate repos.

## Compatible install methods

Verified against upstream docs at <https://docs.saleor.io/setup/docker-compose>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose via saleor-platform | `git clone https://github.com/saleor/saleor-platform && docker compose up` | ✅ | Standard self-hosted path. Includes API + Dashboard + all deps. |
| Kubernetes / Helm | <https://docs.saleor.io/setup/kubernetes> | ✅ | Production K8s deploy. |
| Saleor Cloud | <https://cloud.saleor.io> | ✅ (hosted) | Managed SaaS — free developer tier. |
| Saleor CLI | `npm i -g @saleor/cli && saleor register` | ✅ | Bootstrap + deploy via CLI tool. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| secret_key | "Django SECRET_KEY (generate: `openssl rand -hex 32`)?" | Free-text (sensitive) | All |
| db_password | "PostgreSQL password?" | Free-text (sensitive) | All |
| domain | "Public domain for Saleor API (e.g. `saleor.example.com`)?" | Free-text | Production |
| email_backend | "SMTP host/credentials for transactional emails?" | Free-text | Production |

## Software-layer concerns

### Architecture (three separate repos)

| Component | Repo | Port | Notes |
|---|---|---|---|
| Saleor Core (API) | `github.com/saleor/saleor` | `8000` | Django GraphQL API |
| Saleor Dashboard | `github.com/saleor/saleor-dashboard` | `9000` | React admin UI |
| React Storefront | `github.com/saleor/react-storefront` | *(separate deploy)* | Example storefront — optional |

### Docker Compose quickstart (saleor-platform)

```bash
git clone https://github.com/saleor/saleor-platform
cd saleor-platform

# Copy env files
cp common.env.example common.env
cp backend.env.example backend.env

# Apply database migrations
docker compose run --rm api python manage.py migrate

# Collect static files
docker compose run --rm api python manage.py collectstatic --noinput

# Seed default channel and category
docker compose run --rm api python manage.py populatedb --createsuperuser

docker compose up
```

Dashboard: `http://localhost:9000`  
API: `http://localhost:8000/graphql/`  
Jaeger (tracing): `http://localhost:16686`

### Key environment variables

| Variable | File | Purpose |
|---|---|---|
| `SECRET_KEY` | `backend.env` | Django secret — **change in production** |
| `DATABASE_URL` | `backend.env` | PostgreSQL connection string |
| `REDIS_URL` | `backend.env` | Valkey/Redis URL for Celery |
| `ALLOWED_HOSTS` | `backend.env` | Comma-separated allowed hostnames |
| `ALLOWED_CLIENT_HOSTS` | `backend.env` | Allowed storefront origins (CORS) |
| `DASHBOARD_URL` | compose env | URL of the dashboard (for CORS) |
| `EMAIL_URL` | `backend.env` | Email backend URL (e.g. `smtp://user:pass@host:587/?tls=True`) |
| `DEFAULT_FROM_EMAIL` | `backend.env` | From address for transactional emails |
| `MEDIA_URL` | `backend.env` | Public URL prefix for uploaded media |
| `AWS_MEDIA_BUCKET_NAME` | `backend.env` | S3 bucket for media storage (optional) |
| `AWS_STORAGE_BUCKET_NAME` | `backend.env` | S3 bucket for static files (optional) |

### Services in docker-compose

| Service | Image | Role |
|---|---|---|
| `api` | `ghcr.io/saleor/saleor:3.23` | Django API on port 8000 |
| `dashboard` | `ghcr.io/saleor/saleor-dashboard:3.23` | React dashboard on port 9000 |
| `worker` | `ghcr.io/saleor/saleor:3.23` | Celery async worker |
| `db` | `postgres:15-alpine` | Primary data store |
| `cache` | `valkey/valkey:8.1-alpine` | Task queue + cache |
| `mailpit` | `axllent/mailpit` | Local SMTP catcher for development |
| `jaeger` | `jaegertracing/jaeger` | Distributed tracing (optional) |

### GraphQL API

All Saleor interactions go through a single GraphQL endpoint:

```
POST http://localhost:8000/graphql/
```

Query example:
```graphql
query {
  products(first: 10, channel: "default-channel") {
    edges {
      node {
        id
        name
        slug
      }
    }
  }
}
```

### Channels and multi-currency

Saleor uses **Channels** as first-class entities — each channel controls its own currency, pricing, stock, countries, and available products. Create a channel per storefront/region:

```graphql
mutation {
  channelCreate(input: {
    name: "EU Store"
    slug: "eu-store"
    currencyCode: "EUR"
    countries: ["DE", "FR", "ES"]
  }) {
    channel { id }
  }
}
```

### Data directories

| Path | Contents |
|---|---|
| `saleor-db` volume | PostgreSQL — products, orders, users, channels |
| `saleor-media` volume | Uploaded images and files (shared between api + worker) |

## Upgrade procedure

```bash
cd saleor-platform
git pull
docker compose pull
docker compose run --rm api python manage.py migrate
docker compose up -d
```

Pin all three components to the same major version (e.g. `3.23`). Consult the [Changelog](https://docs.saleor.io/upgrade-guides/overview) for breaking changes.

## Gotchas

- **Three repos must stay in sync.** Saleor Core, Dashboard, and Storefront each have independent release cycles. Use the same minor version for Core + Dashboard to avoid API incompatibilities.
- **No built-in storefront.** Saleor Core is API-only. You must deploy a separate storefront (e.g. `react-storefront`, Next.js Commerce, or your own) to have a customer-facing shop.
- **`SECRET_KEY` must be changed.** Default in `backend.env` is a placeholder — insecure for production.
- **Database migrations are manual.** Run `python manage.py migrate` after each upgrade.
- **Celery worker is required.** Async tasks (email, webhooks, exports) run in the `worker` service. If it's stopped, these silently fail.
- **Jaeger is optional.** The default compose includes Jaeger for distributed tracing. Remove it if you don't need observability overhead.
- **License change at v3.x.** Older Saleor (v2.x) was BSD. Starting v3.x, the license is **BSL 1.1** — free for self-hosted use but cannot offer Saleor SaaS without a commercial license.

## Links

- Upstream: <https://github.com/saleor/saleor>
- Platform (docker-compose): <https://github.com/saleor/saleor-platform>
- Docs: <https://docs.saleor.io>
- Docker Compose setup: <https://docs.saleor.io/setup/docker-compose>
- GraphQL playground: `http://localhost:8000/graphql/` (after local install)
- Dashboard repo: <https://github.com/saleor/saleor-dashboard>
- Storefront (example): <https://github.com/saleor/react-storefront>
- Changelog: <https://docs.saleor.io/upgrade-guides/overview>
