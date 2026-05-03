---
name: revel
description: Revel recipe for open-forge. Open-source community-focused event management and ticketing platform built on Django + PostgreSQL/PostGIS, with Stripe, Celery, and Docker Compose deployment.
---

# Revel

Open-source, community-focused event management and ticketing platform. Upstream: <https://github.com/letsrevel/revel-backend>. Docs: <https://docs.letsrevel.io>.

Revel is a Django 5.2 LTS backend providing event ticketing, membership management, VAT/invoicing, and attendee screening. It is designed for communities that prioritize privacy and self-hosting. The full platform has three repos: backend (this), [frontend (SvelteKit)](https://github.com/letsrevel/revel-frontend), and [infra (Docker Compose)](https://github.com/letsrevel/infra).

Tech stack: Python 3.13 + Django 5.2 LTS + PostgreSQL + PostGIS + Celery + Redis + Stripe.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (dev) | `compose.yaml` in repo | ✅ | Local development; includes Mailpit for email testing |
| Docker Compose (observability) | `docker-compose-observability.yml` | ✅ | Full stack with Grafana, Prometheus, Loki |
| Docker Compose (CI) | `docker-compose-ci.yml` | ✅ | CI/CD pipeline; minimal services |
| `make setup` | Makefile + Docker | ✅ | One-command dev setup (requires `make`, Docker, Python 3.13+, UV) |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | PostgreSQL host/port/db/user/password | Free-text | PostGIS extension required |
| preflight | Redis URL | Free-text | Used by Celery for async tasks |
| preflight | Secret key | Free-text (sensitive) | Django `SECRET_KEY` |
| preflight | Stripe publishable + secret keys | Free-text (sensitive) | Required for paid ticketing |
| preflight | Allowed hosts / CORS origins | Free-text | Production domain(s) |
| smtp | SMTP host, port, user, password | Free-text (sensitive) | Required for emails (tickets, invoices, membership) |
| optional | Apple Developer certificate | File path | Only needed for Apple Wallet ticket integration |
| geo | IP2LOCATION-LITE-DB5.BIN path | File path | Must be downloaded separately from ip2location.com |
| geo | worldcities.csv path | File path | Must be downloaded separately from simplemaps.com |

## Software-layer concerns

Multi-container deployment. Requires PostgreSQL with PostGIS extension, Redis, and Celery workers. Production requires a reverse proxy (Nginx/Caddy) and a Stripe account for paid events.

```yaml
# Minimal production-like compose (refer to letsrevel/infra for full stack)
services:
  db:
    image: postgis/postgis:17-3.5
    environment:
      POSTGRES_DB: revel
      POSTGRES_USER: revel
      POSTGRES_PASSWORD: changeme
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

  backend:
    image: ghcr.io/letsrevel/revel-backend:latest
    environment:
      DATABASE_URL: postgis://revel:changeme@db:5432/revel
      REDIS_URL: redis://redis:6379/0
      SECRET_KEY: your-secret-key
      ALLOWED_HOSTS: yourdomain.com
      STRIPE_PUBLIC_KEY: pk_...
      STRIPE_SECRET_KEY: sk_...
    depends_on:
      - db
      - redis

  celery:
    image: ghcr.io/letsrevel/revel-backend:latest
    command: celery -A config worker -l info
    environment:
      DATABASE_URL: postgis://revel:changeme@db:5432/revel
      REDIS_URL: redis://redis:6379/0
      SECRET_KEY: your-secret-key
    depends_on:
      - db
      - redis

volumes:
  pgdata:
```

For the complete production infra (reverse proxy, observability, frontend), refer to <https://github.com/letsrevel/infra>.

## Upgrade procedure

```bash
git pull
docker compose pull
docker compose up -d
docker compose exec backend python manage.py migrate
```

Always run migrations after upgrading.

## Gotchas

- PostGIS (not plain Postgres) is required — standard `postgres` image will not work.
- IP2Location and worldcities.csv geo data files must be manually downloaded before first run (not bundled due to licensing).
- Emails are fully functional only with a configured SMTP provider — dev environment uses Mailpit (accessible at `localhost:8025`).
- Apple Wallet integration requires an Apple Developer account and certificate — optional feature.
- For production, use the `letsrevel/infra` repo rather than the backend repo's compose files directly.
- VAT/reverse-charge logic is EU-specific; check applicability for your jurisdiction.
